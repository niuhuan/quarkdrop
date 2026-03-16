use crate::workspace::app_paths;
use bytes::Bytes;
use flutter_rust_bridge::for_generated::anyhow;
use futures_util::{stream, StreamExt};
use libquarkpan::{QuarkEntry, QuarkPan};
use serde::{Deserialize, Serialize};
use sha1::{Digest as Sha1Digest, Sha1};
use std::env;
use std::fs;
use std::time::{SystemTime, UNIX_EPOCH};
use x25519_dalek::{PublicKey, StaticSecret};

const QUARKDROP_ROOT_FOLDER_NAME: &str = "QuarkDrop";
const DEVICE_METADATA_FILE_NAME: &str = "device.json";

#[derive(Clone, Debug)]
pub struct LocalDevice {
    pub device_id: String,
    pub device_name: String,
}

#[derive(Clone, Debug)]
pub struct RememberedDevice {
    pub device_id: String,
    pub device_name: String,
    pub is_current: bool,
}

#[derive(Clone, Debug)]
pub struct MailboxState {
    pub mailbox_status_label: String,
    pub mailbox_summary: String,
    pub inbox_job_count: i32,
    pub inbox_previews: Vec<MailboxInboxPreview>,
    pub peer_devices: Vec<DiscoveredPeerDevice>,
}

#[derive(Clone, Debug)]
pub struct MailboxInboxPreview {
    pub id: String,
    pub sender: String,
    pub root_name: String,
    pub summary: String,
    pub size_label: String,
    pub received_at_label: String,
    pub is_ready: bool,
}

#[derive(Clone, Debug)]
pub struct DiscoveredPeerDevice {
    pub device_id: String,
    pub mailbox_folder_id: String,
    pub label: String,
    pub subtitle: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct DeviceMetadata {
    version: u32,
    device_id: String,
    device_name: String,
    #[serde(default)]
    public_key: String,
    updated_at: u64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct StoredLocalDeviceProfile {
    version: u32,
    device_id: String,
    device_name: String,
    private_key_hex: String,
    updated_at: u64,
}

pub fn load_or_create_local_device() -> anyhow::Result<LocalDevice> {
    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;

    let device_id = if paths.device_id_file.exists() {
        let value = fs::read_to_string(&paths.device_id_file)?
            .trim()
            .to_string();
        if value.is_empty() {
            let generated = generate_device_id();
            fs::write(&paths.device_id_file, format!("{generated}\n"))?;
            generated
        } else {
            value
        }
    } else {
        let generated = generate_device_id();
        fs::write(&paths.device_id_file, format!("{generated}\n"))?;
        generated
    };

    let device_name = if paths.device_name_file.exists() {
        let value = fs::read_to_string(&paths.device_name_file)?
            .trim()
            .to_string();
        if value.is_empty() {
            let derived = default_device_name();
            fs::write(&paths.device_name_file, format!("{derived}\n"))?;
            derived
        } else {
            value
        }
    } else {
        let derived = default_device_name();
        fs::write(&paths.device_name_file, format!("{derived}\n"))?;
        derived
    };

    let local_device = LocalDevice {
        device_id,
        device_name,
    };
    let private_key = load_device_private_key()?;
    remember_device_profile(&local_device, &private_key)?;
    Ok(local_device)
}

pub fn save_device_name(name: String) -> anyhow::Result<String> {
    let normalized = name.trim().to_string();
    anyhow::ensure!(!normalized.is_empty(), "Device name cannot be empty.");

    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;
    fs::write(&paths.device_name_file, format!("{normalized}\n"))?;
    let device_id = fs::read_to_string(&paths.device_id_file)?
        .trim()
        .to_string();
    let private_key = load_device_private_key()?;
    remember_device_profile(
        &LocalDevice {
            device_id,
            device_name: normalized.clone(),
        },
        &private_key,
    )?;
    Ok(normalized)
}

pub fn list_remembered_devices() -> anyhow::Result<Vec<RememberedDevice>> {
    let current = load_or_create_local_device()?;
    let paths = app_paths()?;
    fs::create_dir_all(&paths.device_profiles_dir)?;

    let mut devices = fs::read_dir(&paths.device_profiles_dir)?
        .filter_map(|entry| entry.ok())
        .filter_map(|entry| fs::read(entry.path()).ok())
        .filter_map(|bytes| serde_json::from_slice::<StoredLocalDeviceProfile>(&bytes).ok())
        .collect::<Vec<_>>();

    devices.sort_by(|left, right| {
        right
            .updated_at
            .cmp(&left.updated_at)
            .then_with(|| left.device_name.cmp(&right.device_name))
            .then_with(|| left.device_id.cmp(&right.device_id))
    });

    Ok(devices
        .into_iter()
        .map(|profile| RememberedDevice {
            is_current: profile.device_id == current.device_id,
            device_id: profile.device_id,
            device_name: profile.device_name,
        })
        .collect())
}

pub fn restore_remembered_device(device_id: String) -> anyhow::Result<LocalDevice> {
    let normalized = device_id.trim().to_string();
    anyhow::ensure!(!normalized.is_empty(), "Device id cannot be empty.");

    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;
    let profile_path = device_profile_path(&paths, &normalized);
    let payload = fs::read(&profile_path).map_err(|error| {
        anyhow::anyhow!("Unable to restore remembered device `{normalized}`: {error}")
    })?;
    let profile: StoredLocalDeviceProfile = serde_json::from_slice(&payload)?;

    fs::write(&paths.device_id_file, format!("{}\n", profile.device_id))?;
    fs::write(
        &paths.device_name_file,
        format!("{}\n", profile.device_name),
    )?;
    fs::write(
        &paths.device_private_key_file,
        format!("{}\n", profile.private_key_hex),
    )?;

    let local_device = LocalDevice {
        device_id: profile.device_id,
        device_name: profile.device_name,
    };
    let private_key = decode_private_key_hex(profile.private_key_hex.trim())?;
    remember_device_profile(&local_device, &private_key)?;
    Ok(local_device)
}

pub fn bind_cloud_device(device_id: String) -> anyhow::Result<()> {
    let normalized = device_id.trim().to_string();
    anyhow::ensure!(!normalized.is_empty(), "Device id cannot be empty.");

    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;

    fs::write(&paths.device_id_file, format!("{normalized}\n"))?;

    let local_device = load_or_create_local_device()?;
    let private_key = load_device_private_key()?;
    remember_device_profile(&local_device, &private_key)?;
    Ok(())
}

pub(crate) fn load_device_private_key() -> anyhow::Result<[u8; 32]> {
    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;
    if paths.device_private_key_file.exists() {
        let value = fs::read_to_string(&paths.device_private_key_file)?;
        return decode_private_key_hex(value.trim());
    }
    let secret = crate::protocol::crypto::random_key_material();
    fs::write(
        &paths.device_private_key_file,
        format!("{}\n", hex::encode(secret)),
    )?;
    Ok(secret)
}

pub(crate) fn local_public_key_hex() -> anyhow::Result<String> {
    let secret = load_device_private_key()?;
    let public = PublicKey::from(&StaticSecret::from(secret));
    Ok(hex::encode(public.as_bytes()))
}

pub(crate) async fn mailbox_public_key(
    quark: &QuarkPan,
    mailbox_id: &str,
) -> anyhow::Result<String> {
    let metadata = read_device_metadata(quark, mailbox_id)
        .await?
        .ok_or_else(|| anyhow::anyhow!("peer device metadata is missing"))?;
    anyhow::ensure!(
        !metadata.public_key.trim().is_empty(),
        "peer device metadata does not publish a public key yet"
    );
    Ok(metadata.public_key)
}

pub async fn ensure_mailbox_state(
    quark: &QuarkPan,
    manifest_name: &str,
    commit_name: &str,
    local_device: &LocalDevice,
) -> anyhow::Result<MailboxState> {
    let root_id = ensure_protocol_folder(quark, "0", QUARKDROP_ROOT_FOLDER_NAME).await?;
    let mailbox_name = format!("device_{}", local_device.device_id);
    let mailbox_id = ensure_protocol_folder(quark, &root_id, &mailbox_name).await?;
    publish_device_metadata(quark, &mailbox_id, local_device).await?;
    let peer_devices = discover_peer_devices(quark, &root_id, &local_device.device_id).await?;
    let inbox_previews =
        discover_inbox_jobs(quark, &mailbox_id, manifest_name, commit_name).await?;
    let inbox_job_count = i32::try_from(inbox_previews.len()).unwrap_or(i32::MAX);

    Ok(MailboxState {
        mailbox_status_label: "Mailbox ready".to_string(),
        mailbox_summary: format!(
            "QuarkDrop ensured this device mailbox in Quark Drive and found {inbox_job_count} ready relay job(s)."
        ),
        inbox_job_count,
        inbox_previews,
        peer_devices,
    })
}

pub async fn remove_local_mailbox(
    quark: &QuarkPan,
    local_device: &LocalDevice,
) -> anyhow::Result<()> {
    let root_entries = list_all_entries(quark, "0").await?;
    let Some(root) = root_entries
        .iter()
        .find(|entry| entry.dir && entry.file_name == QUARKDROP_ROOT_FOLDER_NAME)
    else {
        return Ok(());
    };
    let mailbox_name = format!("device_{}", local_device.device_id);
    let mailbox_entries = list_all_entries(quark, &root.fid).await?;
    if let Some(mailbox) = mailbox_entries
        .iter()
        .find(|entry| entry.dir && entry.file_name == mailbox_name)
    {
        quark.delete_file(&mailbox.fid).await?;
    }
    Ok(())
}

async fn discover_peer_devices(
    quark: &QuarkPan,
    root_id: &str,
    current_device_id: &str,
) -> anyhow::Result<Vec<DiscoveredPeerDevice>> {
    let mut peers = Vec::new();
    for entry in list_all_entries(quark, root_id).await? {
        if !(entry.dir && entry.file_name.starts_with("device_")) {
            continue;
        }
        let Some(device_id) = entry.file_name.strip_prefix("device_").map(str::to_string) else {
            continue;
        };
        if device_id == current_device_id {
            continue;
        }
        let metadata = read_device_metadata(quark, &entry.fid).await.ok().flatten();
        peers.push(DiscoveredPeerDevice {
            label: metadata
                .as_ref()
                .map(|meta| meta.device_name.clone())
                .filter(|value| !value.is_empty())
                .unwrap_or_else(|| format!("Device {}", short_device_label(&device_id))),
            subtitle: metadata
                .map(|meta| format!("Mailbox discovered for `{}`.", meta.device_id))
                .unwrap_or_else(|| {
                    "Mailbox discovered inside the shared QuarkDrop relay root.".to_string()
                }),
            mailbox_folder_id: entry.fid,
            device_id,
        });
    }

    peers.sort_by(|left, right| left.device_id.cmp(&right.device_id));
    Ok(peers)
}

async fn discover_inbox_jobs(
    quark: &QuarkPan,
    mailbox_id: &str,
    manifest_name: &str,
    commit_name: &str,
) -> anyhow::Result<Vec<MailboxInboxPreview>> {
    let mut jobs = list_all_entries(quark, mailbox_id)
        .await?
        .into_iter()
        .filter(|entry| entry.dir && entry.file_name.starts_with("job_"))
        .collect::<Vec<_>>();

    jobs.sort_by(|left, right| right.updated_at.cmp(&left.updated_at));

    let mut ready = Vec::new();
    for job in jobs {
        let children = list_all_entries(quark, &job.fid).await?;
        let manifest_entry = children
            .iter()
            .find(|entry| entry.file_name == manifest_name);
        let commit_entry = children.iter().find(|entry| entry.file_name == commit_name);
        let (Some(manifest_entry), Some(commit_entry)) = (manifest_entry, commit_entry) else {
            continue;
        };

        let receiver_private_key = match load_device_private_key() {
            Ok(value) => value,
            Err(_) => continue,
        };
        let manifest_bytes = match download_bytes(quark, &manifest_entry.fid).await {
            Ok(value) => value,
            Err(_) => continue,
        };
        let manifest = match crate::protocol::manifest::decode_from_bytes(
            &manifest_bytes,
            &receiver_private_key,
        ) {
            Ok(value) => value,
            Err(_) => continue,
        };
        let commit_bytes = match download_bytes(quark, &commit_entry.fid).await {
            Ok(value) => value,
            Err(_) => continue,
        };
        let commit = match crate::protocol::commit::decode_from_bytes(
            &commit_bytes,
            &receiver_private_key,
        ) {
            Ok(value) => value,
            Err(_) => continue,
        };
        if commit.manifest_digest != sha256_hex(&manifest_bytes) {
            continue;
        }
        let file_count = manifest
            .entries
            .iter()
            .filter(|entry| entry.kind == crate::protocol::manifest::ManifestEntryKind::File)
            .count();
        let total_size = manifest.entries.iter().map(|entry| entry.size).sum::<u64>();

        ready.push(MailboxInboxPreview {
            id: job.fid,
            sender: if manifest.sender_device_name.is_empty() {
                format!("Device {}", short_device_label(&manifest.sender_device_id))
            } else {
                manifest.sender_device_name
            },
            root_name: manifest.root_name,
            summary: format!(
                "Ready relay package with {file_count} file(s) after `{manifest_name}` and `{commit_name}` were both uploaded."
            ),
            size_label: size_label(total_size),
            received_at_label: observed_label(job.updated_at),
            is_ready: true,
        });
    }

    Ok(ready)
}

async fn ensure_protocol_folder(
    quark: &QuarkPan,
    parent_folder: &str,
    folder_name: &str,
) -> anyhow::Result<String> {
    let entries = list_all_entries(quark, parent_folder).await?;
    if let Some(existing) = entries.iter().find(|entry| entry.file_name == folder_name) {
        anyhow::ensure!(
            existing.dir,
            "Expected `{folder_name}` under parent `{parent_folder}` to be a folder.",
        );
        return Ok(existing.fid.clone());
    }

    Ok(quark
        .create_folder()
        .parent_folder(parent_folder.to_string())
        .name(folder_name.to_string())
        .prepare()?
        .request()
        .await?)
}

pub(crate) async fn list_all_entries(
    quark: &QuarkPan,
    folder_id: &str,
) -> anyhow::Result<Vec<QuarkEntry>> {
    let mut entries = Vec::new();
    let mut page_no = 1;
    let page_size = 100;

    loop {
        let page = quark
            .list()
            .folder_id(folder_id.to_string())
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

fn observed_label(updated_at: u64) -> String {
    format!("Updated {}", updated_at)
}

fn default_device_name() -> String {
    env::var("DEVICE_NAME")
        .or_else(|_| env::var("HOSTNAME"))
        .or_else(|_| env::var("COMPUTERNAME"))
        .or_else(|_| env::var("NAME"))
        .ok()
        .map(|value| value.trim().to_string())
        .filter(|value| !value.is_empty())
        .unwrap_or_else(|| {
            if cfg!(target_os = "ios") {
                "iPhone".to_string()
            } else if cfg!(target_os = "android") {
                "Android Device".to_string()
            } else if cfg!(target_os = "macos") {
                "Mac".to_string()
            } else if cfg!(target_os = "windows") {
                "PC".to_string()
            } else {
                "This Device".to_string()
            }
        })
}

fn generate_device_id() -> String {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_nanos())
        .unwrap_or(0);
    format!("qd{:x}", nanos)
}

fn remember_device_profile(
    local_device: &LocalDevice,
    private_key: &[u8; 32],
) -> anyhow::Result<()> {
    let paths = app_paths()?;
    fs::create_dir_all(&paths.device_profiles_dir)?;
    let profile = StoredLocalDeviceProfile {
        version: 1,
        device_id: local_device.device_id.clone(),
        device_name: local_device.device_name.clone(),
        private_key_hex: hex::encode(private_key),
        updated_at: SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|duration| duration.as_millis() as u64)
            .unwrap_or(0),
    };
    fs::write(
        device_profile_path(&paths, &local_device.device_id),
        serde_json::to_vec_pretty(&profile)?,
    )?;
    Ok(())
}

fn device_profile_path(paths: &crate::workspace::AppPaths, device_id: &str) -> std::path::PathBuf {
    paths.device_profiles_dir.join(format!("{device_id}.json"))
}

fn short_device_label(device_id: &str) -> &str {
    let end = device_id
        .char_indices()
        .nth(8)
        .map(|(index, _)| index)
        .unwrap_or(device_id.len());
    &device_id[..end]
}

async fn publish_device_metadata(
    quark: &QuarkPan,
    mailbox_id: &str,
    local_device: &LocalDevice,
) -> anyhow::Result<()> {
    let existing = list_all_entries(quark, mailbox_id).await?;
    if let Some(old) = existing
        .iter()
        .find(|entry| entry.file_name == DEVICE_METADATA_FILE_NAME && entry.file)
    {
        quark.delete_file(&old.fid).await?;
    }

    let payload = serde_json::to_vec(&DeviceMetadata {
        version: 1,
        device_id: local_device.device_id.clone(),
        device_name: local_device.device_name.clone(),
        public_key: local_public_key_hex()?,
        updated_at: SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|duration| duration.as_millis() as u64)
            .unwrap_or(0),
    })?;
    upload_small_bytes(quark, mailbox_id, DEVICE_METADATA_FILE_NAME, payload).await?;
    Ok(())
}

async fn read_device_metadata(
    quark: &QuarkPan,
    mailbox_id: &str,
) -> anyhow::Result<Option<DeviceMetadata>> {
    let children = list_all_entries(quark, mailbox_id).await?;
    let Some(metadata_file) = children
        .iter()
        .find(|entry| entry.file_name == DEVICE_METADATA_FILE_NAME && entry.file)
    else {
        return Ok(None);
    };
    Ok(Some(download_json(quark, &metadata_file.fid).await?))
}

async fn download_json<T>(quark: &QuarkPan, file_id: &str) -> anyhow::Result<T>
where
    T: for<'de> Deserialize<'de>,
{
    let bytes = download_bytes(quark, file_id).await?;
    Ok(serde_json::from_slice(&bytes)?)
}

async fn download_bytes(quark: &QuarkPan, file_id: &str) -> anyhow::Result<Vec<u8>> {
    let mut stream = quark
        .download()
        .file_id(file_id.to_string())
        .prepare()?
        .stream()
        .await?;
    let mut bytes = Vec::new();
    while let Some(chunk) = stream.next().await {
        bytes.extend_from_slice(&chunk?);
    }
    Ok(bytes)
}

async fn upload_small_bytes(
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
        .parent_folder(parent_folder_id)
        .name(name)
        .size(bytes.len() as u64)
        .md5(md5)
        .sha1(sha1)
        .prepare()
        .await?
    {
        libquarkpan::UploadPrepareResult::RapidUploaded { file_id } => Ok(file_id),
        libquarkpan::UploadPrepareResult::NeedUpload(session) => {
            let stream =
                stream::once(
                    async move { Ok::<Bytes, libquarkpan::QuarkPanError>(Bytes::from(bytes)) },
                );
            Ok(session.upload_stream(stream).await?.file_id)
        }
    }
}

fn size_label(size_bytes: u64) -> String {
    const UNITS: [&str; 5] = ["B", "KB", "MB", "GB", "TB"];
    let mut value = size_bytes as f64;
    let mut unit_index = 0usize;
    while value >= 1024.0 && unit_index < UNITS.len() - 1 {
        value /= 1024.0;
        unit_index += 1;
    }
    if unit_index == 0 {
        format!("{size_bytes} {}", UNITS[unit_index])
    } else {
        format!("{value:.1} {}", UNITS[unit_index])
    }
}

fn sha256_hex(bytes: &[u8]) -> String {
    use sha2::Digest;
    let mut hasher = sha2::Sha256::new();
    hasher.update(bytes);
    hex::encode(hasher.finalize())
}

fn decode_private_key_hex(value: &str) -> anyhow::Result<[u8; 32]> {
    let bytes = hex::decode(value)?;
    anyhow::ensure!(
        bytes.len() == 32,
        "device private key must be 32 bytes, got {}",
        bytes.len()
    );
    let mut secret = [0u8; 32];
    secret.copy_from_slice(&bytes);
    Ok(secret)
}
