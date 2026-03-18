use crate::protocol::commit::CommitMarker;
use crate::protocol::crypto::{
    decrypt_blob_frame, derive_file_key, BLOB_FRAME_PLAIN_BYTES, CHACHA_TAG_BYTES,
    CONTENT_CIPHER_NAME,
};
use crate::protocol::manifest::{JobManifest, ManifestEntry, ManifestEntryKind};
use crate::task::state::{TaskDirection, TaskSnapshot, TaskStage};
use crate::task::store::upsert_task_snapshot;
use flutter_rust_bridge::for_generated::anyhow;
use futures_util::StreamExt;
use libquarkpan::{QuarkEntry, QuarkPan};
use sha2::{Digest, Sha256};
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::fs;
use tokio::io::{AsyncReadExt, AsyncWriteExt};

pub async fn receive_job(
    quark: &QuarkPan,
    job_folder_id: &str,
    output_dir: &str,
) -> anyhow::Result<String> {
    receive_job_impl(quark, job_folder_id, output_dir).await
}

pub async fn resume_receive_task(
    quark: &QuarkPan,
    snapshot: &TaskSnapshot,
) -> anyhow::Result<String> {
    let local_root = Path::new(&snapshot.local_path);
    let output_dir = local_root
        .parent()
        .ok_or_else(|| anyhow::anyhow!("cannot derive output directory from saved task path"))?;
    receive_job_impl(
        quark,
        &snapshot.remote_job_folder_id,
        &output_dir.to_string_lossy(),
    )
    .await
}

async fn receive_job_impl(
    quark: &QuarkPan,
    job_folder_id: &str,
    output_dir: &str,
) -> anyhow::Result<String> {
    let children = list_all_entries(quark, job_folder_id).await?;
    let manifest_entry = children
        .iter()
        .find(|entry| entry.file_name == crate::protocol::manifest::MANIFEST_FILE_NAME)
        .ok_or_else(|| anyhow::anyhow!("manifest.enc is missing from this job"))?;
    let commit_entry = children
        .iter()
        .find(|entry| entry.file_name == crate::protocol::commit::COMMIT_FILE_NAME)
        .ok_or_else(|| anyhow::anyhow!("commit.ok.enc is missing from this job"))?;

    let receiver_private_key = crate::device::load_device_private_key()?;
    let manifest_bytes = download_bytes(quark, &manifest_entry.fid).await?;
    let commit_bytes = download_bytes(quark, &commit_entry.fid).await?;
    let manifest: JobManifest =
        crate::protocol::manifest::decode_from_bytes(&manifest_bytes, &receiver_private_key)?;
    let commit: CommitMarker =
        crate::protocol::commit::decode_from_bytes(&commit_bytes, &receiver_private_key)?;

    anyhow::ensure!(
        commit.manifest_digest == sha256_hex(&manifest_bytes),
        "The remote commit marker does not match the manifest digest.",
    );

    let root_output = Path::new(output_dir).join(&manifest.root_name);
    let mut snapshot = TaskSnapshot {
        job_id: manifest.job_id.clone(),
        stage: TaskStage::DownloadingBlobs,
        direction: TaskDirection::Receive,
        local_path: root_output.to_string_lossy().into_owned(),
        remote_job_folder_id: job_folder_id.to_string(),
        remote_mailbox_folder_id: String::new(),
        display_name: manifest.root_name.clone(),
        counterpart_device_id: manifest.sender_device_id.clone(),
        counterpart_label: if manifest.sender_device_name.is_empty() {
            format!("Device {}", manifest.sender_device_id)
        } else {
            manifest.sender_device_name.clone()
        },
        size_bytes: manifest.entries.iter().map(|entry| entry.size).sum(),
        transferred_bytes: 0,
        protocol_name: if commit.protocol_version >= 2 {
            "encrypted-sized-v1".to_string()
        } else {
            "plain-v0".to_string()
        },
        manifest_created_at_unix_ms: manifest.created_at,
        content_key_seed_hex: manifest.content_key_seed_hex.clone(),
        last_error_message: String::new(),
        updated_at_unix_ms: now_unix_ms(),
    };
    persist_snapshot(&snapshot)?;
    let receive_result: anyhow::Result<String> = async {
        let blobs_dir = children
            .iter()
            .find(|entry| entry.dir && entry.file_name == "blobs")
            .ok_or_else(|| anyhow::anyhow!("blobs folder is missing from this job"))?;
        let blob_entries = list_all_entries(quark, &blobs_dir.fid).await?;

        if manifest.root_kind == "directory" {
            fs::create_dir_all(&root_output).await?;
        } else {
            let parent = root_output
                .parent()
                .ok_or_else(|| anyhow::anyhow!("cannot determine output parent directory"))?;
            fs::create_dir_all(parent).await?;
        }

        let content_key_seed = if manifest.content_key_seed_hex.trim().is_empty() {
            None
        } else {
            Some(decode_content_key_seed(&manifest.content_key_seed_hex)?)
        };

        let mut completed_before_entry = 0u64;
        for entry in &manifest.entries {
            let relative = safe_relative_path(&entry.path)?;
            match entry.kind {
                ManifestEntryKind::Directory => {
                    fs::create_dir_all(root_output.join(relative)).await?;
                }
                ManifestEntryKind::File => {
                    let destination = if manifest.root_kind == "directory" {
                        root_output.join(relative)
                    } else {
                        Path::new(output_dir).join(relative)
                    };
                    if let Some(parent) = destination.parent() {
                        fs::create_dir_all(parent).await?;
                    }
                    let temp = destination.with_extension("quarkdrop.part");
                    if file_matches_digest(&destination, &entry.sha256_plain).await? {
                        completed_before_entry = completed_before_entry.saturating_add(entry.size);
                        continue;
                    }

                    let resumable_bytes = prepare_temp_file_for_resume(&temp, entry).await?;
                    let mut resumed_bytes = 0u64;
                    let mut hasher = Sha256::new();
                    let mut writer = if resumable_bytes > 0 {
                        resumed_bytes = resumable_bytes;
                        let mut reader = fs::File::open(&temp).await?;
                        let mut buffer = vec![0u8; 1024 * 1024];
                        let mut remaining = resumable_bytes;
                        while remaining > 0 {
                            let read = reader.read(&mut buffer).await?;
                            if read == 0 {
                                break;
                            }
                            let take = (read as u64).min(remaining) as usize;
                            hasher.update(&buffer[..take]);
                            remaining -= take as u64;
                        }
                        fs::OpenOptions::new().append(true).open(&temp).await?
                    } else {
                        fs::File::create(&temp).await?
                    };

                    let file_key = if is_encrypted_entry(entry) {
                        let seed = content_key_seed.ok_or_else(|| {
                            anyhow::anyhow!("encrypted manifest is missing content key seed")
                        })?;
                        Some(derive_file_key(&seed, &entry.entry_id)?)
                    } else {
                        None
                    };

                    let mut completed_before_blob = 0u64;
                    for (blob_index, blob_id) in entry.blob_ids.iter().enumerate() {
                        let blob = blob_entries
                            .iter()
                            .find(|candidate| candidate.fid == *blob_id)
                            .ok_or_else(|| {
                                anyhow::anyhow!("missing blob `{blob_id}` referenced by manifest")
                            })?;
                        let blob_plain_size = entry
                            .blob_plain_sizes
                            .get(blob_index)
                            .copied()
                            .unwrap_or_else(|| {
                                entry
                                    .blob_sizes
                                    .get(blob_index)
                                    .copied()
                                    .unwrap_or(blob.size)
                            });
                        if resumed_bytes >= completed_before_blob + blob_plain_size {
                            completed_before_blob += blob_plain_size;
                            snapshot.transferred_bytes = snapshot.transferred_bytes.max(
                                completed_before_entry
                                    .saturating_add(completed_before_blob)
                                    .min(snapshot.size_bytes),
                            );
                            continue;
                        }
                        if let Some(file_key) = file_key.as_ref() {
                            let start_plain = resumed_bytes.saturating_sub(completed_before_blob);
                            download_encrypted_blob(
                                quark,
                                &blob.fid,
                                entry,
                                file_key,
                                blob_index,
                                blob_plain_size,
                                start_plain,
                                &mut writer,
                                &mut hasher,
                                &mut resumed_bytes,
                            )
                            .await?;
                        } else {
                            let start_offset = resumed_bytes.saturating_sub(completed_before_blob);
                            let mut request = quark.download().fid(blob.fid.clone());
                            if start_offset > 0 {
                                request = request.start_offset(start_offset);
                            }
                            let mut stream = request.prepare()?.stream().await?;
                            while let Some(chunk) = stream.next().await {
                                let chunk = chunk?;
                                hasher.update(&chunk);
                                writer.write_all(&chunk).await?;
                                resumed_bytes += chunk.len() as u64;
                            }
                        }
                        completed_before_blob += blob_plain_size;
                        snapshot.transferred_bytes = snapshot.transferred_bytes.max(
                            completed_before_entry
                                .saturating_add(completed_before_blob)
                                .min(snapshot.size_bytes),
                        );
                        snapshot.updated_at_unix_ms = now_unix_ms();
                        persist_snapshot(&snapshot)?;
                    }
                    writer.flush().await?;
                    drop(writer);

                    snapshot.stage = TaskStage::Verifying;
                    snapshot.transferred_bytes = snapshot.transferred_bytes.max(
                        completed_before_entry
                            .saturating_add(entry.size)
                            .min(snapshot.size_bytes),
                    );
                    snapshot.last_error_message.clear();
                    snapshot.updated_at_unix_ms = now_unix_ms();
                    persist_snapshot(&snapshot)?;

                    let digest = hex::encode(hasher.finalize());
                    anyhow::ensure!(
                        digest == entry.sha256_plain,
                        "Downloaded file digest mismatch for `{}`",
                        destination.display()
                    );
                    fs::rename(&temp, &destination).await?;
                    snapshot.stage = TaskStage::DownloadingBlobs;
                    snapshot.transferred_bytes = snapshot.transferred_bytes.max(
                        completed_before_entry
                            .saturating_add(entry.size)
                            .min(snapshot.size_bytes),
                    );
                    snapshot.last_error_message.clear();
                    snapshot.updated_at_unix_ms = now_unix_ms();
                    persist_snapshot(&snapshot)?;
                    completed_before_entry = completed_before_entry.saturating_add(entry.size);
                }
            }
        }

        snapshot.stage = TaskStage::CleanupRemote;
        snapshot.transferred_bytes = snapshot.size_bytes;
        snapshot.last_error_message.clear();
        snapshot.updated_at_unix_ms = now_unix_ms();
        persist_snapshot(&snapshot)?;
        quark.delete(job_folder_id).await?;

        snapshot.stage = TaskStage::Done;
        snapshot.transferred_bytes = snapshot.size_bytes;
        snapshot.last_error_message.clear();
        snapshot.updated_at_unix_ms = now_unix_ms();
        persist_snapshot(&snapshot)?;
        Ok(manifest.job_id.clone())
    }
    .await;

    match receive_result {
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

async fn download_encrypted_blob(
    quark: &QuarkPan,
    file_id: &str,
    entry: &ManifestEntry,
    file_key: &[u8; 32],
    blob_index: usize,
    blob_plain_size: u64,
    start_plain_offset: u64,
    writer: &mut fs::File,
    hasher: &mut Sha256,
    resumed_bytes: &mut u64,
) -> anyhow::Result<()> {
    let frame_floor =
        (start_plain_offset / BLOB_FRAME_PLAIN_BYTES as u64) * BLOB_FRAME_PLAIN_BYTES as u64;
    let start_offset = encrypted_cipher_offset(frame_floor);
    let mut request = quark.download().fid(file_id.to_string());
    if start_offset > 0 {
        request = request.start_offset(start_offset);
    }
    let mut stream = request.prepare()?.stream().await?;
    let mut buffer = Vec::new();
    let mut frame_index = frame_floor / BLOB_FRAME_PLAIN_BYTES as u64;
    let mut written_for_blob = frame_floor;
    while let Some(chunk) = stream.next().await {
        let chunk = chunk?;
        buffer.extend_from_slice(&chunk);
        loop {
            if buffer.len() < 4 {
                break;
            }
            let mut len_bytes = [0u8; 4];
            len_bytes.copy_from_slice(&buffer[..4]);
            let plain_len = u32::from_le_bytes(len_bytes) as usize;
            let frame_total = 4 + plain_len + CHACHA_TAG_BYTES;
            if buffer.len() < frame_total {
                break;
            }
            let ciphertext = buffer[4..frame_total].to_vec();
            buffer.drain(..frame_total);
            let plain = decrypt_blob_frame(
                file_key,
                &entry.entry_id,
                blob_index,
                frame_index,
                &ciphertext,
            )?;
            anyhow::ensure!(
                plain.len() == plain_len,
                "decrypted frame length mismatch for `{}`",
                entry.entry_id
            );
            writer.write_all(&plain).await?;
            hasher.update(&plain);
            written_for_blob += plain.len() as u64;
            *resumed_bytes += plain.len() as u64;
            frame_index += 1;
            if written_for_blob >= blob_plain_size {
                break;
            }
        }
        if written_for_blob >= blob_plain_size {
            break;
        }
    }
    anyhow::ensure!(
        written_for_blob == blob_plain_size,
        "encrypted blob size mismatch for `{}`",
        entry.entry_id
    );
    Ok(())
}

async fn download_bytes(quark: &QuarkPan, file_id: &str) -> anyhow::Result<Vec<u8>> {
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

async fn file_matches_digest(path: &Path, expected_sha256: &str) -> anyhow::Result<bool> {
    if expected_sha256.is_empty() {
        return Ok(false);
    }
    let Ok(_) = fs::metadata(path).await else {
        return Ok(false);
    };
    let mut file = fs::File::open(path).await?;
    let mut hasher = Sha256::new();
    let mut buffer = vec![0u8; 1024 * 1024];
    loop {
        let read = file.read(&mut buffer).await?;
        if read == 0 {
            break;
        }
        hasher.update(&buffer[..read]);
    }
    Ok(hex::encode(hasher.finalize()) == expected_sha256)
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

fn safe_relative_path(segments: &[String]) -> anyhow::Result<PathBuf> {
    let mut path = PathBuf::new();
    for segment in segments {
        anyhow::ensure!(
            !segment.is_empty() && segment != "." && segment != "..",
            "invalid manifest path segment `{segment}`"
        );
        path.push(segment);
    }
    anyhow::ensure!(
        path.components().count() > 0,
        "manifest path cannot be empty"
    );
    Ok(path)
}

fn persist_snapshot(snapshot: &TaskSnapshot) -> anyhow::Result<()> {
    upsert_task_snapshot(snapshot)?;
    Ok(())
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

fn decode_content_key_seed(value: &str) -> anyhow::Result<[u8; 32]> {
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

fn is_encrypted_entry(entry: &ManifestEntry) -> bool {
    entry.cipher == CONTENT_CIPHER_NAME
}

async fn prepare_temp_file_for_resume(temp: &Path, entry: &ManifestEntry) -> anyhow::Result<u64> {
    let Ok(metadata) = fs::metadata(temp).await else {
        return Ok(0);
    };
    let mut resumable = metadata.len().min(entry.size);
    if is_encrypted_entry(entry) {
        resumable = align_encrypted_resume_bytes(entry, resumable);
    }
    let file = fs::OpenOptions::new().write(true).open(temp).await?;
    file.set_len(resumable).await?;
    Ok(resumable)
}

fn align_encrypted_resume_bytes(entry: &ManifestEntry, existing_bytes: u64) -> u64 {
    let mut aligned = 0u64;
    let mut remaining = existing_bytes;
    for blob_plain_size in entry.blob_plain_sizes.iter().copied() {
        if remaining == 0 {
            break;
        }
        if remaining >= blob_plain_size {
            aligned += blob_plain_size;
            remaining -= blob_plain_size;
            continue;
        }
        aligned += (remaining / BLOB_FRAME_PLAIN_BYTES as u64) * BLOB_FRAME_PLAIN_BYTES as u64;
        break;
    }
    aligned
}

fn encrypted_cipher_offset(plain_offset: u64) -> u64 {
    let full_frames = plain_offset / BLOB_FRAME_PLAIN_BYTES as u64;
    full_frames * (4 + BLOB_FRAME_PLAIN_BYTES as u64 + CHACHA_TAG_BYTES as u64)
}
