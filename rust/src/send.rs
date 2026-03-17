use crate::device::LocalDevice;
use crate::protocol::commit::{CommitMarker, COMMIT_FILE_NAME};
use crate::protocol::crypto::{
    self, derive_file_key, encrypt_blob_frame, BLOB_FRAME_PLAIN_BYTES, CONTENT_CIPHER_NAME,
};
use crate::protocol::manifest::{
    JobManifest, ManifestEntry, ManifestEntryKind, MANIFEST_FILE_NAME,
};
use crate::task::state::{TaskDirection, TaskSnapshot, TaskStage};
use crate::task::store::upsert_task_snapshot;
use async_stream::try_stream;
use bytes::Bytes;
use flutter_rust_bridge::for_generated::anyhow;
use futures_util::stream;
use libquarkpan::{QuarkEntry, QuarkPan, QuarkPanError, UploadPrepareResult};
use sha1::{Digest as Sha1Digest, Sha1};
use sha2::Sha256;
use std::collections::VecDeque;
use std::fs;
use std::io::{Read, SeekFrom};
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::io::{AsyncReadExt, AsyncSeekExt};
use tokio_util::io::ReaderStream;
use uuid::Uuid;

const BLOBS_FOLDER_NAME: &str = "blobs";
const SCAN_BUFFER_BYTES: usize = 1024 * 1024;
const QUARK_OBJECT_LIMIT_BYTES: u64 = 4 * 1024 * 1024 * 1024;
const ENCRYPTED_SAFE_BLOB_LIMIT_BYTES: u64 = 3 * 1024 * 1024 * 1024;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum PayloadCipher {
    PlainV0,
    EncryptedSizedV1,
}

impl PayloadCipher {
    fn manifest_name(self) -> &'static str {
        match self {
            PayloadCipher::PlainV0 => "plain-v0",
            PayloadCipher::EncryptedSizedV1 => "encrypted-sized-v1",
        }
    }

    fn content_cipher_name(self) -> &'static str {
        match self {
            PayloadCipher::PlainV0 => "plain-v0",
            PayloadCipher::EncryptedSizedV1 => CONTENT_CIPHER_NAME,
        }
    }

    fn blob_limit_bytes(self) -> u64 {
        match self {
            PayloadCipher::PlainV0 => QUARK_OBJECT_LIMIT_BYTES,
            PayloadCipher::EncryptedSizedV1 => ENCRYPTED_SAFE_BLOB_LIMIT_BYTES,
        }
    }

    fn manifest_version(self) -> u32 {
        match self {
            PayloadCipher::PlainV0 => 1,
            PayloadCipher::EncryptedSizedV1 => 2,
        }
    }

    fn from_manifest_name(value: &str) -> Option<Self> {
        match value {
            "plain-v0" => Some(PayloadCipher::PlainV0),
            "encrypted-sized-v1" => Some(PayloadCipher::EncryptedSizedV1),
            _ => None,
        }
    }
}

#[derive(Clone, Debug)]
enum LocalEntryKind {
    File,
    Directory,
}

#[derive(Clone, Debug)]
struct LocalEntryPlan {
    kind: LocalEntryKind,
    absolute_path: PathBuf,
    relative_path: Vec<String>,
    size: u64,
}

#[derive(Clone, Debug)]
struct LocalPayloadPlan {
    root_kind: String,
    root_name: String,
    entries: Vec<LocalEntryPlan>,
    total_size: u64,
}

#[derive(Clone, Debug)]
struct PlannedBlob {
    blob_index: usize,
    name: String,
    offset: u64,
    size: u64,
    plain_size: u64,
    md5: String,
    sha1: String,
    sha256_cipher: String,
}

pub async fn send_local_path(
    quark: &QuarkPan,
    local_device: &LocalDevice,
    peer_mailbox_folder_id: &str,
    peer_device_id: &str,
    peer_label: &str,
    source_path: &str,
) -> anyhow::Result<String> {
    send_local_path_impl(
        quark,
        local_device,
        peer_mailbox_folder_id,
        peer_device_id,
        peer_label,
        source_path,
        None,
    )
    .await
}

pub async fn resume_send_task(
    quark: &QuarkPan,
    local_device: &LocalDevice,
    snapshot: &TaskSnapshot,
) -> anyhow::Result<String> {
    send_local_path_impl(
        quark,
        local_device,
        &snapshot.remote_mailbox_folder_id,
        &snapshot.counterpart_device_id,
        &snapshot.counterpart_label,
        &snapshot.local_path,
        Some(snapshot),
    )
    .await
}

async fn send_local_path_impl(
    quark: &QuarkPan,
    local_device: &LocalDevice,
    peer_mailbox_folder_id: &str,
    peer_device_id: &str,
    peer_label: &str,
    source_path: &str,
    existing_task: Option<&TaskSnapshot>,
) -> anyhow::Result<String> {
    let source = Path::new(source_path);
    let payload = collect_payload_plan(source)?;
    let payload_cipher = existing_task
        .and_then(|task| PayloadCipher::from_manifest_name(&task.protocol_name))
        .unwrap_or(PayloadCipher::EncryptedSizedV1);
    let manifest_created_at = existing_task
        .map(|task| task.manifest_created_at_unix_ms)
        .filter(|value| *value > 0)
        .unwrap_or_else(now_unix_ms);
    let content_key_seed = if payload_cipher == PayloadCipher::EncryptedSizedV1 {
        existing_task
            .and_then(|task| decode_content_key_seed(&task.content_key_seed_hex).ok())
            .unwrap_or_else(crypto::random_key_material)
    } else {
        [0u8; 32]
    };

    let (job_id, remote_job_folder_id) = if let Some(task) = existing_task {
        (task.job_id.clone(), task.remote_job_folder_id.clone())
    } else {
        let job_id = Uuid::new_v4().to_string();
        let remote_job_folder_id =
            create_folder(quark, peer_mailbox_folder_id, &format!("job_{job_id}")).await?;
        (job_id, remote_job_folder_id)
    };

    let mut snapshot = TaskSnapshot {
        job_id: job_id.clone(),
        stage: TaskStage::Scanning,
        direction: TaskDirection::Send,
        local_path: source.to_string_lossy().into_owned(),
        remote_job_folder_id: remote_job_folder_id.clone(),
        remote_mailbox_folder_id: existing_task
            .map(|task| task.remote_mailbox_folder_id.clone())
            .unwrap_or_else(|| peer_mailbox_folder_id.to_string()),
        display_name: payload.root_name.clone(),
        counterpart_device_id: peer_device_id.to_string(),
        counterpart_label: peer_label.to_string(),
        size_bytes: payload.total_size,
        protocol_name: payload_cipher.manifest_name().to_string(),
        manifest_created_at_unix_ms: manifest_created_at,
        content_key_seed_hex: if payload_cipher == PayloadCipher::EncryptedSizedV1 {
            hex::encode(content_key_seed)
        } else {
            String::new()
        },
        last_error_message: String::new(),
        updated_at_unix_ms: now_unix_ms(),
    };
    persist_snapshot(&snapshot)?;
    let send_result: anyhow::Result<String> = async {
        let blobs_folder_id =
            ensure_folder(quark, &remote_job_folder_id, BLOBS_FOLDER_NAME).await?;
        let mut existing_blob_entries = list_all_entries(quark, &blobs_folder_id).await?;
        let existing_job_entries = list_all_entries(quark, &remote_job_folder_id).await?;
        if existing_job_entries
            .iter()
            .any(|entry| entry.file_name == COMMIT_FILE_NAME)
        {
            snapshot.stage = TaskStage::Done;
            snapshot.last_error_message.clear();
            snapshot.updated_at_unix_ms = now_unix_ms();
            persist_snapshot(&snapshot)?;
            return Ok(job_id.clone());
        }

        let receiver_public_key = if payload_cipher == PayloadCipher::EncryptedSizedV1 {
            anyhow::ensure!(
                !snapshot.remote_mailbox_folder_id.is_empty(),
                "encrypted send resume requires the saved peer mailbox folder id"
            );
            Some(
                crate::device::mailbox_public_key(quark, &snapshot.remote_mailbox_folder_id)
                    .await?,
            )
        } else {
            None
        };

        snapshot.stage = TaskStage::UploadingBlobs;
        snapshot.last_error_message.clear();
        snapshot.updated_at_unix_ms = now_unix_ms();
        persist_snapshot(&snapshot)?;

        let mut manifest_entries = Vec::with_capacity(payload.entries.len());
        for entry in &payload.entries {
            match entry.kind {
                LocalEntryKind::Directory => {
                    manifest_entries.push(ManifestEntry {
                        entry_id: entry_id_for_path(&entry.relative_path, &entry.kind),
                        kind: ManifestEntryKind::Directory,
                        path: entry.relative_path.clone(),
                        size: 0,
                        sha256_plain: String::new(),
                        cipher: payload_cipher.content_cipher_name().to_string(),
                        blob_ids: Vec::new(),
                        blob_sizes: Vec::new(),
                        blob_plain_sizes: Vec::new(),
                        blob_sha256_cipher: Vec::new(),
                    });
                }
                LocalEntryKind::File => {
                    let entry_id = entry_id_for_path(&entry.relative_path, &entry.kind);
                    let (sha256_plain, blobs) = plan_file_blobs(
                        &entry.absolute_path,
                        &entry.relative_path,
                        &entry_id,
                        payload_cipher,
                        &content_key_seed,
                        payload_cipher.blob_limit_bytes(),
                    )?;
                    let mut blob_ids = Vec::with_capacity(blobs.len());
                    let mut blob_sizes = Vec::with_capacity(blobs.len());
                    let mut blob_plain_sizes = Vec::with_capacity(blobs.len());
                    let mut blob_sha256_cipher = Vec::with_capacity(blobs.len());

                    for blob in &blobs {
                        let file_id = if let Some(existing) = existing_blob_entries
                            .iter()
                            .find(|candidate| candidate.file_name == blob.name)
                        {
                            existing.fid.clone()
                        } else {
                            let uploaded = upload_file_chunk(
                                quark,
                                &blobs_folder_id,
                                &entry.absolute_path,
                                &entry_id,
                                payload_cipher,
                                &content_key_seed,
                                blob,
                            )
                            .await?;
                            existing_blob_entries.push(QuarkEntry {
                                fid: uploaded.clone(),
                                file_name: blob.name.clone(),
                                pdir_fid: blobs_folder_id.clone(),
                                size: blob.size,
                                format_type: String::new(),
                                status: 0,
                                created_at: 0,
                                updated_at: 0,
                                dir: false,
                                file: true,
                            });
                            uploaded
                        };
                        blob_ids.push(file_id);
                        blob_sizes.push(blob.size);
                        blob_plain_sizes.push(blob.plain_size);
                        blob_sha256_cipher.push(blob.sha256_cipher.clone());
                    }

                    manifest_entries.push(ManifestEntry {
                        entry_id,
                        kind: ManifestEntryKind::File,
                        path: entry.relative_path.clone(),
                        size: entry.size,
                        sha256_plain,
                        cipher: payload_cipher.content_cipher_name().to_string(),
                        blob_ids,
                        blob_sizes,
                        blob_plain_sizes,
                        blob_sha256_cipher,
                    });
                }
            }
        }

        let manifest = JobManifest {
            version: payload_cipher.manifest_version(),
            job_id: job_id.clone(),
            created_at: manifest_created_at,
            sender_device_id: local_device.device_id.clone(),
            sender_device_name: local_device.device_name.clone(),
            receiver_device_id: peer_device_id.to_string(),
            receiver_device_name: peer_label.to_string(),
            root_kind: payload.root_kind,
            root_name: payload.root_name,
            content_key_seed_hex: if payload_cipher == PayloadCipher::EncryptedSizedV1 {
                hex::encode(content_key_seed)
            } else {
                String::new()
            },
            entries: manifest_entries,
        };

        snapshot.stage = TaskStage::UploadingManifest;
        snapshot.last_error_message.clear();
        snapshot.updated_at_unix_ms = now_unix_ms();
        persist_snapshot(&snapshot)?;
        let manifest_bytes = if let Some(existing) = existing_job_entries
            .iter()
            .find(|entry| entry.file_name == MANIFEST_FILE_NAME)
        {
            download_bytes(quark, &existing.fid).await?
        } else {
            let bytes = match (&payload_cipher, receiver_public_key.as_deref()) {
                (PayloadCipher::EncryptedSizedV1, Some(public_key)) => {
                    crate::protocol::manifest::encode_for_receiver(&manifest, public_key)?
                }
                _ => serde_json::to_vec(&manifest)?,
            };
            upload_bytes(
                quark,
                &remote_job_folder_id,
                MANIFEST_FILE_NAME,
                bytes.clone(),
            )
            .await?;
            bytes
        };

        let commit_plain = CommitMarker {
            job_id: job_id.clone(),
            manifest_digest: sha256_hex(&manifest_bytes),
            protocol_version: payload_cipher.manifest_version(),
        };
        let commit_bytes = match (&payload_cipher, receiver_public_key.as_deref()) {
            (PayloadCipher::EncryptedSizedV1, Some(public_key)) => {
                crate::protocol::commit::encode_for_receiver(
                    &commit_plain,
                    peer_device_id,
                    public_key,
                )?
            }
            _ => serde_json::to_vec(&commit_plain)?,
        };

        snapshot.stage = TaskStage::UploadingCommit;
        snapshot.last_error_message.clear();
        snapshot.updated_at_unix_ms = now_unix_ms();
        persist_snapshot(&snapshot)?;
        if !existing_job_entries
            .iter()
            .any(|entry| entry.file_name == COMMIT_FILE_NAME)
        {
            upload_bytes(quark, &remote_job_folder_id, COMMIT_FILE_NAME, commit_bytes).await?;
        }

        snapshot.stage = TaskStage::Done;
        snapshot.last_error_message.clear();
        snapshot.updated_at_unix_ms = now_unix_ms();
        persist_snapshot(&snapshot)?;
        Ok(job_id.clone())
    }
    .await;

    match send_result {
        Ok(job_id) => Ok(job_id),
        Err(error) => {
            snapshot.stage = TaskStage::Failed;
            snapshot.last_error_message = error.to_string();
            snapshot.updated_at_unix_ms = now_unix_ms();
            let _ = persist_snapshot(&snapshot);
            Err(error)
        }
    }
}

fn collect_payload_plan(source: &Path) -> anyhow::Result<LocalPayloadPlan> {
    let metadata = fs::metadata(source)?;
    let root_name = source
        .file_name()
        .map(|value| value.to_string_lossy().into_owned())
        .or_else(|| {
            source
                .components()
                .next_back()
                .map(|value| value.as_os_str().to_string_lossy().into_owned())
        })
        .filter(|value| !value.is_empty())
        .ok_or_else(|| anyhow::anyhow!("cannot determine file or folder name from path"))?;

    if metadata.is_file() {
        return Ok(LocalPayloadPlan {
            root_kind: "file".to_string(),
            root_name: root_name.clone(),
            total_size: metadata.len(),
            entries: vec![LocalEntryPlan {
                kind: LocalEntryKind::File,
                absolute_path: source.to_path_buf(),
                relative_path: vec![root_name],
                size: metadata.len(),
            }],
        });
    }

    anyhow::ensure!(
        metadata.is_dir(),
        "The selected path is not a regular file or folder."
    );
    let mut queue = VecDeque::from([source.to_path_buf()]);
    let mut entries = Vec::new();
    let mut total_size = 0u64;

    while let Some(dir_path) = queue.pop_front() {
        let mut children = fs::read_dir(&dir_path)?.collect::<Result<Vec<_>, _>>()?;
        children.sort_by_key(|item| item.file_name());

        for child in children {
            let child_path = child.path();
            let child_metadata = child.metadata()?;
            let relative = relative_segments(source, &child_path)?;
            if child_metadata.is_dir() {
                entries.push(LocalEntryPlan {
                    kind: LocalEntryKind::Directory,
                    absolute_path: child_path.clone(),
                    relative_path: relative,
                    size: 0,
                });
                queue.push_back(child_path);
            } else if child_metadata.is_file() {
                total_size = total_size.saturating_add(child_metadata.len());
                entries.push(LocalEntryPlan {
                    kind: LocalEntryKind::File,
                    absolute_path: child_path,
                    relative_path: relative,
                    size: child_metadata.len(),
                });
            }
        }
    }

    Ok(LocalPayloadPlan {
        root_kind: "directory".to_string(),
        root_name,
        entries,
        total_size,
    })
}

fn relative_segments(root: &Path, path: &Path) -> anyhow::Result<Vec<String>> {
    let relative = path
        .strip_prefix(root)
        .map_err(|_| anyhow::anyhow!("failed to compute relative path"))?;
    let segments = relative
        .components()
        .map(|segment| segment.as_os_str().to_string_lossy().into_owned())
        .collect::<Vec<_>>();
    anyhow::ensure!(!segments.is_empty(), "relative path cannot be empty");
    Ok(segments)
}

fn plan_file_blobs(
    path: &Path,
    relative_path: &[String],
    entry_id: &str,
    payload_cipher: PayloadCipher,
    content_key_seed: &[u8; 32],
    blob_limit_bytes: u64,
) -> anyhow::Result<(String, Vec<PlannedBlob>)> {
    match payload_cipher {
        PayloadCipher::PlainV0 => plan_plain_file_blobs(path, relative_path, blob_limit_bytes),
        PayloadCipher::EncryptedSizedV1 => plan_encrypted_file_blobs(
            path,
            relative_path,
            entry_id,
            content_key_seed,
            blob_limit_bytes,
        ),
    }
}

fn plan_plain_file_blobs(
    path: &Path,
    relative_path: &[String],
    blob_limit_bytes: u64,
) -> anyhow::Result<(String, Vec<PlannedBlob>)> {
    anyhow::ensure!(blob_limit_bytes > 0, "blob limit must be greater than zero");
    let mut file = fs::File::open(path)?;
    let mut buffer = vec![0u8; SCAN_BUFFER_BYTES];
    let mut file_sha256 = Sha256::new();
    let mut chunk_md5 = md5::Context::new();
    let mut chunk_sha1 = Sha1::new();
    let mut chunk_sha256 = Sha256::new();
    let mut chunk_size = 0u64;
    let mut chunk_offset = 0u64;
    let mut blobs = Vec::new();

    loop {
        let read = file.read(&mut buffer)?;
        if read == 0 {
            break;
        }

        let mut cursor = 0usize;
        while cursor < read {
            let remaining = read - cursor;
            let capacity = (blob_limit_bytes - chunk_size) as usize;
            let take = remaining.min(capacity);
            let slice = &buffer[cursor..cursor + take];

            file_sha256.update(slice);
            chunk_md5.consume(slice);
            chunk_sha1.update(slice);
            chunk_sha256.update(slice);
            chunk_size += take as u64;
            cursor += take;

            if chunk_size == blob_limit_bytes {
                blobs.push(finalize_blob(
                    relative_path,
                    blobs.len(),
                    chunk_offset,
                    chunk_size,
                    chunk_size,
                    &mut chunk_md5,
                    &mut chunk_sha1,
                    &mut chunk_sha256,
                ));
                chunk_offset += chunk_size;
                chunk_size = 0;
            }
        }
    }

    if chunk_size > 0 {
        blobs.push(finalize_blob(
            relative_path,
            blobs.len(),
            chunk_offset,
            chunk_size,
            chunk_size,
            &mut chunk_md5,
            &mut chunk_sha1,
            &mut chunk_sha256,
        ));
    }

    Ok((hex::encode(file_sha256.finalize()), blobs))
}

fn plan_encrypted_file_blobs(
    path: &Path,
    relative_path: &[String],
    entry_id: &str,
    content_key_seed: &[u8; 32],
    blob_limit_bytes: u64,
) -> anyhow::Result<(String, Vec<PlannedBlob>)> {
    anyhow::ensure!(blob_limit_bytes > 0, "blob limit must be greater than zero");
    let mut file = fs::File::open(path)?;
    let mut buffer = vec![0u8; BLOB_FRAME_PLAIN_BYTES];
    let file_key = derive_file_key(content_key_seed, entry_id)?;
    let mut file_sha256 = Sha256::new();
    let mut blobs = Vec::new();
    let mut blob_plain_size = 0u64;
    let mut blob_cipher_size = 0u64;
    let mut blob_offset = 0u64;
    let mut blob_md5 = md5::Context::new();
    let mut blob_sha1 = Sha1::new();
    let mut blob_sha256 = Sha256::new();
    let mut frame_index = 0u64;

    loop {
        let capacity =
            (blob_limit_bytes - blob_plain_size).min(BLOB_FRAME_PLAIN_BYTES as u64) as usize;
        let read = file.read(&mut buffer[..capacity])?;
        if read == 0 {
            break;
        }
        let frame_plain = &buffer[..read];
        file_sha256.update(frame_plain);
        let encrypted =
            encrypt_blob_frame(&file_key, entry_id, blobs.len(), frame_index, frame_plain)?;
        let mut framed = Vec::with_capacity(4 + encrypted.len());
        framed.extend_from_slice(&(read as u32).to_le_bytes());
        framed.extend_from_slice(&encrypted);
        blob_md5.consume(&framed);
        blob_sha1.update(&framed);
        blob_sha256.update(&framed);
        blob_plain_size += read as u64;
        blob_cipher_size += framed.len() as u64;
        frame_index += 1;

        if blob_plain_size == blob_limit_bytes {
            blobs.push(finalize_blob(
                relative_path,
                blobs.len(),
                blob_offset,
                blob_cipher_size,
                blob_plain_size,
                &mut blob_md5,
                &mut blob_sha1,
                &mut blob_sha256,
            ));
            blob_offset += blob_plain_size;
            blob_plain_size = 0;
            blob_cipher_size = 0;
            frame_index = 0;
        }
    }

    if blob_plain_size > 0 {
        blobs.push(finalize_blob(
            relative_path,
            blobs.len(),
            blob_offset,
            blob_cipher_size,
            blob_plain_size,
            &mut blob_md5,
            &mut blob_sha1,
            &mut blob_sha256,
        ));
    }

    Ok((hex::encode(file_sha256.finalize()), blobs))
}

fn finalize_blob(
    relative_path: &[String],
    blob_index: usize,
    offset: u64,
    size: u64,
    plain_size: u64,
    chunk_md5: &mut md5::Context,
    chunk_sha1: &mut Sha1,
    chunk_sha256: &mut Sha256,
) -> PlannedBlob {
    let md5 = format!(
        "{:x}",
        std::mem::replace(chunk_md5, md5::Context::new()).compute()
    );
    let sha1 = hex::encode(chunk_sha1.finalize_reset());
    let sha256_cipher = hex::encode(chunk_sha256.finalize_reset());
    PlannedBlob {
        blob_index,
        name: blob_name(relative_path, blob_index),
        offset,
        size,
        plain_size,
        md5,
        sha1,
        sha256_cipher,
    }
}

async fn create_folder(
    quark: &QuarkPan,
    parent_folder_id: &str,
    name: &str,
) -> anyhow::Result<String> {
    Ok(quark
        .create_folder()
        .pdir_fid(parent_folder_id)
        .file_name(name)
        .prepare()?
        .request()
        .await?)
}

async fn ensure_folder(
    quark: &QuarkPan,
    parent_folder_id: &str,
    name: &str,
) -> anyhow::Result<String> {
    let entries = list_all_entries(quark, parent_folder_id).await?;
    if let Some(existing) = entries
        .iter()
        .find(|entry| entry.dir && entry.file_name == name)
    {
        return Ok(existing.fid.clone());
    }
    create_folder(quark, parent_folder_id, name).await
}

async fn upload_file_chunk(
    quark: &QuarkPan,
    parent_folder_id: &str,
    source_path: &Path,
    entry_id: &str,
    payload_cipher: PayloadCipher,
    content_key_seed: &[u8; 32],
    blob: &PlannedBlob,
) -> anyhow::Result<String> {
    match quark
        .upload()
        .pdir_fid(parent_folder_id)
        .file_name(&blob.name)
        .size(blob.size)
        .md5(&blob.md5)
        .sha1(&blob.sha1)
        .prepare()
        .await?
    {
        UploadPrepareResult::RapidUploaded { fid } => Ok(fid),
        UploadPrepareResult::NeedUpload(session) => match payload_cipher {
            PayloadCipher::PlainV0 => {
                let mut file = tokio::fs::File::open(source_path).await?;
                file.seek(SeekFrom::Start(blob.offset)).await?;
                let stream = ReaderStream::new(file.take(blob.size));
                Ok(session.upload_stream(stream).await?.fid)
            }
            PayloadCipher::EncryptedSizedV1 => {
                let stream =
                    encrypted_blob_stream(source_path, entry_id, content_key_seed, blob).await?;
                Ok(session.upload_stream(stream).await?.fid)
            }
        },
    }
}

async fn encrypted_blob_stream(
    source_path: &Path,
    entry_id: &str,
    content_key_seed: &[u8; 32],
    blob: &PlannedBlob,
) -> anyhow::Result<impl futures_util::Stream<Item = Result<Bytes, std::io::Error>>> {
    let mut file = tokio::fs::File::open(source_path).await?;
    file.seek(SeekFrom::Start(blob.offset)).await?;
    let file_key = derive_file_key(content_key_seed, entry_id)
        .map_err(|error| std::io::Error::other(error.to_string()))?;
    let entry_id = entry_id.to_string();
    let blob_index = blob.blob_index;
    let plain_remaining = blob.plain_size;
    Ok(try_stream! {
        let mut reader = file.take(plain_remaining);
        let mut buffer = vec![0u8; BLOB_FRAME_PLAIN_BYTES];
        let mut frame_index = 0u64;
        loop {
            let read = reader.read(&mut buffer).await?;
            if read == 0 {
                break;
            }
            let encrypted = encrypt_blob_frame(&file_key, &entry_id, blob_index, frame_index, &buffer[..read])
                .map_err(|error| std::io::Error::other(error.to_string()))?;
            let mut framed = Vec::with_capacity(4 + encrypted.len());
            framed.extend_from_slice(&(read as u32).to_le_bytes());
            framed.extend_from_slice(&encrypted);
            frame_index += 1;
            yield Bytes::from(framed);
        }
    })
}

async fn upload_bytes(
    quark: &QuarkPan,
    parent_folder_id: &str,
    name: &str,
    bytes: Vec<u8>,
) -> anyhow::Result<String> {
    let md5 = format!("{:x}", md5::compute(&bytes));
    let mut sha1 = Sha1::new();
    sha1.update(&bytes);
    let sha1 = hex::encode(sha1.finalize());

    match quark
        .upload()
        .pdir_fid(parent_folder_id)
        .file_name(name)
        .size(bytes.len() as u64)
        .md5(md5)
        .sha1(sha1)
        .prepare()
        .await?
    {
        UploadPrepareResult::RapidUploaded { fid } => Ok(fid),
        UploadPrepareResult::NeedUpload(session) => {
            let stream =
                stream::once(async move { Ok::<Bytes, QuarkPanError>(Bytes::from(bytes)) });
            Ok(session.upload_stream(stream).await?.fid)
        }
    }
}

async fn download_bytes(quark: &QuarkPan, file_id: &str) -> anyhow::Result<Vec<u8>> {
    use futures_util::StreamExt;
    let mut stream = quark
        .download()
        .fid(file_id.to_string())
        .prepare()?
        .stream()
        .await?;
    let mut bytes = Vec::new();
    while let Some(chunk) = stream.next().await {
        bytes.extend_from_slice(&chunk?);
    }
    Ok(bytes)
}

fn persist_snapshot(snapshot: &TaskSnapshot) -> anyhow::Result<()> {
    upsert_task_snapshot(snapshot)?;
    Ok(())
}

async fn list_all_entries(quark: &QuarkPan, folder_id: &str) -> anyhow::Result<Vec<QuarkEntry>> {
    let mut entries = Vec::new();
    let mut page_no = 1;
    let page_size = 100;
    loop {
        let page = quark
            .list()
            .pdir_fid(folder_id.to_string())
            .page(page_no)
            .size(page_size)
            .prepare()?
            .request()
            .await?;
        let count = page.entries.len();
        entries.extend(page.entries);
        if count < page_size as usize {
            break;
        }
        page_no += 1;
    }
    Ok(entries)
}

fn now_unix_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_millis() as u64)
        .unwrap_or(0)
}

fn sha256_hex(bytes: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(bytes);
    hex::encode(hasher.finalize())
}

fn blob_name(relative_path: &[String], blob_index: usize) -> String {
    let mut hasher = Sha256::new();
    hasher.update(relative_path.join("/").as_bytes());
    let digest = hex::encode(hasher.finalize());
    format!("b_{}_{}", &digest[..16], blob_index)
}

fn entry_id_for_path(relative_path: &[String], kind: &LocalEntryKind) -> String {
    let mut hasher = Sha256::new();
    hasher.update(match kind {
        LocalEntryKind::File => b"file".as_slice(),
        LocalEntryKind::Directory => b"directory".as_slice(),
    });
    hasher.update(relative_path.join("/").as_bytes());
    let digest = hex::encode(hasher.finalize());
    format!("entry_{}", &digest[..24])
}

fn decode_content_key_seed(value: &str) -> anyhow::Result<[u8; 32]> {
    anyhow::ensure!(!value.trim().is_empty(), "missing content key seed");
    let bytes = hex::decode(value)?;
    anyhow::ensure!(
        bytes.len() == 32,
        "content key seed must be 32 bytes, got {}",
        bytes.len()
    );
    let mut seed = [0u8; 32];
    seed.copy_from_slice(&bytes);
    Ok(seed)
}

#[cfg(feature = "full-test")]
pub(crate) async fn stage_partial_send_for_test(
    quark: &QuarkPan,
    local_device: &LocalDevice,
    peer_mailbox_folder_id: &str,
    peer_device_id: &str,
    peer_label: &str,
    source_path: &str,
) -> anyhow::Result<TaskSnapshot> {
    let source = Path::new(source_path);
    let payload = collect_payload_plan(source)?;
    anyhow::ensure!(
        payload.root_kind == "file",
        "partial send test currently expects a single file source"
    );
    let file_entry = payload
        .entries
        .iter()
        .find(|entry| matches!(entry.kind, LocalEntryKind::File))
        .ok_or_else(|| anyhow::anyhow!("file payload did not produce a file entry"))?;
    let payload_cipher = PayloadCipher::EncryptedSizedV1;
    let manifest_created_at = now_unix_ms();
    let content_key_seed = crypto::random_key_material();
    let job_id = Uuid::new_v4().to_string();
    let remote_job_folder_id =
        create_folder(quark, peer_mailbox_folder_id, &format!("job_{job_id}")).await?;
    let blobs_folder_id = ensure_folder(quark, &remote_job_folder_id, BLOBS_FOLDER_NAME).await?;
    let entry_id = entry_id_for_path(&file_entry.relative_path, &file_entry.kind);
    let (_, blobs) = plan_file_blobs(
        &file_entry.absolute_path,
        &file_entry.relative_path,
        &entry_id,
        payload_cipher,
        &content_key_seed,
        payload_cipher.blob_limit_bytes(),
    )?;
    let first_blob = blobs
        .first()
        .ok_or_else(|| anyhow::anyhow!("no upload blobs were planned for `{source_path}`"))?;
    upload_file_chunk(
        quark,
        &blobs_folder_id,
        &file_entry.absolute_path,
        &entry_id,
        payload_cipher,
        &content_key_seed,
        first_blob,
    )
    .await?;

    let snapshot = TaskSnapshot {
        job_id,
        stage: TaskStage::UploadingBlobs,
        direction: TaskDirection::Send,
        local_path: source.to_string_lossy().into_owned(),
        remote_job_folder_id,
        remote_mailbox_folder_id: peer_mailbox_folder_id.to_string(),
        display_name: payload.root_name,
        counterpart_device_id: peer_device_id.to_string(),
        counterpart_label: peer_label.to_string(),
        size_bytes: payload.total_size,
        protocol_name: payload_cipher.manifest_name().to_string(),
        manifest_created_at_unix_ms: manifest_created_at,
        content_key_seed_hex: hex::encode(content_key_seed),
        updated_at_unix_ms: now_unix_ms(),
    };
    persist_snapshot(&snapshot)?;
    let _ = local_device;
    Ok(snapshot)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs::{create_dir_all, write};

    #[test]
    fn plain_cipher_uses_full_quark_limit() {
        assert_eq!(
            PayloadCipher::PlainV0.blob_limit_bytes(),
            4 * 1024 * 1024 * 1024
        );
        assert_eq!(
            PayloadCipher::EncryptedSizedV1.blob_limit_bytes(),
            3 * 1024 * 1024 * 1024
        );
    }

    #[test]
    fn plans_directory_entries_and_nested_files() {
        let root = temp_test_dir("folder-plan");
        create_dir_all(root.join("docs/nested")).unwrap();
        write(root.join("hello.txt"), b"abc").unwrap();
        write(root.join("docs/nested/readme.md"), b"xyz").unwrap();

        let plan = collect_payload_plan(&root).unwrap();
        assert_eq!(plan.root_kind, "directory");
        assert_eq!(plan.total_size, 6);
        assert!(plan.entries.iter().any(|entry| {
            matches!(entry.kind, LocalEntryKind::Directory)
                && entry.relative_path == vec!["docs".to_string()]
        }));
        assert!(plan.entries.iter().any(|entry| {
            matches!(entry.kind, LocalEntryKind::File)
                && entry.relative_path
                    == vec![
                        "docs".to_string(),
                        "nested".to_string(),
                        "readme.md".to_string(),
                    ]
        }));

        std::fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn plans_multiple_blobs_for_small_limit() {
        let root = temp_test_dir("blob-plan");
        write(&root, b"abcdefghijk").unwrap();

        let (_, blobs) = plan_file_blobs(
            &root,
            &["blob-plan".to_string()],
            "entry_blob_plan",
            PayloadCipher::PlainV0,
            &[0u8; 32],
            4,
        )
        .unwrap();
        let sizes = blobs.into_iter().map(|blob| blob.size).collect::<Vec<_>>();
        assert_eq!(sizes, vec![4, 4, 3]);

        std::fs::remove_file(root).unwrap();
    }

    #[test]
    fn encrypted_blob_plan_tracks_plain_and_cipher_sizes() {
        let root = temp_test_dir("encrypted-blob-plan");
        write(&root, b"abcdefgh").unwrap();

        let (_, blobs) = plan_file_blobs(
            &root,
            &["encrypted-blob-plan".to_string()],
            "entry_encrypted_blob_plan",
            PayloadCipher::EncryptedSizedV1,
            &[7u8; 32],
            4,
        )
        .unwrap();
        let plain_sizes = blobs.iter().map(|blob| blob.plain_size).collect::<Vec<_>>();
        let cipher_sizes = blobs.iter().map(|blob| blob.size).collect::<Vec<_>>();
        assert_eq!(plain_sizes, vec![4, 4]);
        assert!(cipher_sizes.into_iter().all(|size| size > 4));

        std::fs::remove_file(root).unwrap();
    }

    fn temp_test_dir(name: &str) -> PathBuf {
        std::env::temp_dir().join(format!("quarkdrop-{name}-{}", Uuid::new_v4()))
    }
}
