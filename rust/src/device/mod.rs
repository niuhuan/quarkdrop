use crate::workspace::app_paths;
use argon2::Argon2;
use bytes::Bytes;
use chacha20poly1305::aead::{Aead, KeyInit};
use chacha20poly1305::{ChaCha20Poly1305, Key, Nonce};
use flutter_rust_bridge::for_generated::anyhow;
use futures_util::{stream, StreamExt};
use libquarkpan::{QuarkEntry, QuarkPan};
use rand::rngs::OsRng;
use rand::RngCore;
use serde::{Deserialize, Serialize};
use sha1::{Digest as Sha1Digest, Sha1};
use sha2::Sha256;
use std::env;
use std::fs;
use std::sync::{OnceLock, RwLock};
use std::time::{SystemTime, UNIX_EPOCH};
use x25519_dalek::{PublicKey, StaticSecret};

const QUARKDROP_ROOT_FOLDER_NAME: &str = "QuarkDrop";
const DEVICE_METADATA_FILE_NAME: &str = "device.json";
const DEVICE_METADATA_BAK_FILE_NAME: &str = "device.bak.json";
const KEY_VERIFY_FILE_NAME: &str = "key_verify.json";
const VERIFY_PLAINTEXT: &[u8] = b"quarkdrop-verify-ok-v1";

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
    #[serde(default, skip_serializing_if = "Option::is_none")]
    encrypted_key: Option<EncryptedPrivateKey>,
    updated_at: u64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub(crate) struct EncryptedPrivateKey {
    version: u32,
    algorithm: String,
    argon2_salt: String,
    nonce: String,
    ciphertext: String,
}

static UNLOCKED_KEY: OnceLock<RwLock<Option<[u8; 32]>>> = OnceLock::new();
static CLOUD_VERIFY_CACHED: OnceLock<RwLock<Option<bool>>> = OnceLock::new();

fn unlocked_key_cell() -> &'static RwLock<Option<[u8; 32]>> {
    UNLOCKED_KEY.get_or_init(|| RwLock::new(None))
}

fn cloud_verify_cache() -> &'static RwLock<Option<bool>> {
    CLOUD_VERIFY_CACHED.get_or_init(|| RwLock::new(None))
}

pub fn reset_cloud_verify_cache() {
    *cloud_verify_cache()
        .write()
        .expect("cloud verify cache poisoned") = None;
}

pub fn reset_runtime_state() {
    lock_key();
    reset_cloud_verify_cache();
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct StoredLocalDeviceProfile {
    version: u32,
    device_id: String,
    device_name: String,
    encrypted_key: EncryptedPrivateKey,
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

    Ok(LocalDevice {
        device_id,
        device_name,
    })
}

pub fn save_device_name(name: String) -> anyhow::Result<String> {
    let normalized = name.trim().to_string();
    anyhow::ensure!(!normalized.is_empty(), "Device name cannot be empty.");

    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;
    fs::write(&paths.device_name_file, format!("{normalized}\n"))?;
    // Optionally update profile if key file is available
    if paths.device_private_key_file.exists() {
        let device_id = fs::read_to_string(&paths.device_id_file)?
            .trim()
            .to_string();
        let _ = remember_device_profile(&LocalDevice {
            device_id,
            device_name: normalized.clone(),
        });
    }
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
        serde_json::to_vec_pretty(&profile.encrypted_key)?,
    )?;
    lock_key();

    Ok(LocalDevice {
        device_id: profile.device_id,
        device_name: profile.device_name,
    })
}

pub fn bind_cloud_device(device_id: String) -> anyhow::Result<()> {
    let normalized = device_id.trim().to_string();
    anyhow::ensure!(!normalized.is_empty(), "Device id cannot be empty.");

    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;

    // Record old device ID as excluded before switching
    if paths.device_id_file.exists() {
        let old_id = fs::read_to_string(&paths.device_id_file)?
            .trim()
            .to_string();
        if !old_id.is_empty() && old_id != normalized {
            add_excluded_device_id(&old_id)?;
        }
    }

    fs::write(&paths.device_id_file, format!("{normalized}\n"))?;

    load_or_create_local_device()?;
    Ok(())
}

pub(crate) fn load_device_private_key() -> anyhow::Result<[u8; 32]> {
    let guard = unlocked_key_cell()
        .read()
        .expect("unlocked key lock poisoned");
    match *guard {
        Some(key) => Ok(key),
        None => anyhow::bail!("Device key is locked. Unlock with password first."),
    }
}

pub fn is_key_unlocked() -> bool {
    unlocked_key_cell()
        .read()
        .expect("unlocked key lock poisoned")
        .is_some()
}

pub async fn has_cloud_password_verify(quark: &QuarkPan, root_id: &str) -> anyhow::Result<bool> {
    let entries = list_all_entries(quark, root_id).await?;
    Ok(entries
        .iter()
        .any(|e| e.file && e.file_name == KEY_VERIFY_FILE_NAME))
}

pub async fn has_cloud_password_verify_cached(quark: &QuarkPan) -> anyhow::Result<bool> {
    {
        let guard = cloud_verify_cache()
            .read()
            .expect("cloud verify cache poisoned");
        if let Some(cached) = *guard {
            return Ok(cached);
        }
    }
    let root_id = ensure_protocol_folder(quark, "0", QUARKDROP_ROOT_FOLDER_NAME).await?;
    let result = has_cloud_password_verify(quark, &root_id).await?;
    *cloud_verify_cache()
        .write()
        .expect("cloud verify cache poisoned") = Some(result);
    Ok(result)
}

pub async fn create_cloud_password(quark: &QuarkPan, password: &str) -> anyhow::Result<()> {
    let password = password.trim();
    anyhow::ensure!(!password.is_empty(), "Password cannot be empty.");

    let root_id = ensure_protocol_folder(quark, "0", QUARKDROP_ROOT_FOLDER_NAME).await?;

    // Create verify blob
    let verify_encrypted = encrypt_private_key_blob(VERIFY_PLAINTEXT, password)?;
    let verify_bytes = serde_json::to_vec_pretty(&verify_encrypted)?;
    upload_small_bytes(quark, &root_id, KEY_VERIFY_FILE_NAME, verify_bytes).await?;
    *cloud_verify_cache()
        .write()
        .expect("cloud verify cache poisoned") = Some(true);

    // Generate and encrypt local private key
    let secret = crate::protocol::crypto::random_key_material();
    let encrypted = encrypt_private_key(&secret, password)?;
    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;
    fs::write(
        &paths.device_private_key_file,
        serde_json::to_vec_pretty(&encrypted)?,
    )?;
    *unlocked_key_cell()
        .write()
        .expect("unlocked key lock poisoned") = Some(secret);

    // Update profile
    let local_device = load_or_create_local_device()?;
    let _ = remember_device_profile(&local_device);
    Ok(())
}

pub async fn verify_cloud_password(quark: &QuarkPan, password: &str) -> anyhow::Result<()> {
    let root_id = ensure_protocol_folder(quark, "0", QUARKDROP_ROOT_FOLDER_NAME).await?;

    // Download and verify the cloud verification blob
    let entries = list_all_entries(quark, &root_id).await?;
    let verify_entry = entries
        .iter()
        .find(|e| e.file && e.file_name == KEY_VERIFY_FILE_NAME)
        .ok_or_else(|| anyhow::anyhow!("Cloud password verification file not found."))?;
    let verify_bytes = download_bytes(quark, &verify_entry.fid).await?;
    let verify_encrypted: EncryptedPrivateKey = serde_json::from_slice(&verify_bytes)?;
    let decrypted = decrypt_private_key_blob(&verify_encrypted, password)
        .map_err(|_| anyhow::anyhow!("Incorrect password."))?;
    anyhow::ensure!(
        decrypted == VERIFY_PLAINTEXT,
        "Password verification failed — data mismatch."
    );

    // Password is correct. Ensure local private key exists.
    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;
    if paths.device_private_key_file.exists() {
        // Decrypt existing local key
        let data = fs::read(&paths.device_private_key_file)?;
        let encrypted: EncryptedPrivateKey = serde_json::from_slice(&data)?;
        let key = decrypt_private_key(&encrypted, password)?;
        *unlocked_key_cell()
            .write()
            .expect("unlocked key lock poisoned") = Some(key);
    } else {
        // New device: generate new key pair
        let secret = crate::protocol::crypto::random_key_material();
        let encrypted = encrypt_private_key(&secret, password)?;
        fs::write(
            &paths.device_private_key_file,
            serde_json::to_vec_pretty(&encrypted)?,
        )?;
        *unlocked_key_cell()
            .write()
            .expect("unlocked key lock poisoned") = Some(secret);
    }

    // Update profile
    let local_device = load_or_create_local_device()?;
    let _ = remember_device_profile(&local_device);
    Ok(())
}

pub async fn change_cloud_password(
    quark: &QuarkPan,
    old_password: &str,
    new_password: &str,
) -> anyhow::Result<()> {
    let new_password = new_password.trim();
    anyhow::ensure!(!new_password.is_empty(), "New password cannot be empty.");

    let root_id = ensure_protocol_folder(quark, "0", QUARKDROP_ROOT_FOLDER_NAME).await?;

    // Verify old password
    let entries = list_all_entries(quark, &root_id).await?;
    let verify_entry = entries
        .iter()
        .find(|e| e.file && e.file_name == KEY_VERIFY_FILE_NAME)
        .ok_or_else(|| anyhow::anyhow!("Cloud password verification file not found."))?;
    let verify_bytes = download_bytes(quark, &verify_entry.fid).await?;
    let old_verify: EncryptedPrivateKey = serde_json::from_slice(&verify_bytes)?;
    let decrypted = decrypt_private_key_blob(&old_verify, old_password)
        .map_err(|_| anyhow::anyhow!("Incorrect old password."))?;
    anyhow::ensure!(
        decrypted == VERIFY_PLAINTEXT,
        "Old password verification failed."
    );

    // Re-encrypt verify blob with new password and upload
    let new_verify = encrypt_private_key_blob(VERIFY_PLAINTEXT, new_password)?;
    quark.delete(&verify_entry.fid).await?;
    upload_small_bytes(
        quark,
        &root_id,
        KEY_VERIFY_FILE_NAME,
        serde_json::to_vec_pretty(&new_verify)?,
    )
    .await?;

    // Re-encrypt local key
    let key = load_device_private_key()?;
    let new_encrypted = encrypt_private_key(&key, new_password)?;
    let paths = app_paths()?;
    fs::write(
        &paths.device_private_key_file,
        serde_json::to_vec_pretty(&new_encrypted)?,
    )?;

    // Re-encrypt all local profiles
    if paths.device_profiles_dir.exists() {
        for entry in fs::read_dir(&paths.device_profiles_dir)?.filter_map(|e| e.ok()) {
            let Ok(bytes) = fs::read(entry.path()) else {
                continue;
            };
            let Ok(mut profile) = serde_json::from_slice::<StoredLocalDeviceProfile>(&bytes) else {
                continue;
            };
            let Ok(pk) = decrypt_private_key(&profile.encrypted_key, old_password) else {
                continue;
            };
            let Ok(new_enc) = encrypt_private_key(&pk, new_password) else {
                continue;
            };
            profile.encrypted_key = new_enc;
            if let Ok(data) = serde_json::to_vec_pretty(&profile) {
                let _ = fs::write(entry.path(), data);
            }
        }
    }

    // Re-encrypt cloud device profiles
    for entry in &entries {
        if !(entry.dir && entry.file_name.starts_with("device_")) {
            continue;
        }
        let children = list_all_entries(quark, &entry.fid).await?;
        let Some(meta_file) = children
            .iter()
            .find(|c| c.file && c.file_name == DEVICE_METADATA_FILE_NAME)
        else {
            continue;
        };
        let Ok(meta_bytes) = download_bytes(quark, &meta_file.fid).await else {
            continue;
        };
        let Ok(mut meta) = serde_json::from_slice::<DeviceMetadata>(&meta_bytes) else {
            continue;
        };
        if meta.encrypted_key.is_none() {
            continue;
        }
        let old_enc = meta.encrypted_key.as_ref().unwrap();
        let Ok(pk) = decrypt_private_key(old_enc, old_password) else {
            continue;
        };
        let Ok(new_enc) = encrypt_private_key(&pk, new_password) else {
            continue;
        };
        meta.encrypted_key = Some(new_enc);
        let new_payload = serde_json::to_vec(&meta)?;
        if let Some(old_bak) = children
            .iter()
            .find(|c| c.file && c.file_name == DEVICE_METADATA_BAK_FILE_NAME)
        {
            quark.delete(&old_bak.fid).await?;
        }
        quark
            .rename()
            .fid(meta_file.fid.clone())
            .file_name(DEVICE_METADATA_BAK_FILE_NAME.to_string())
            .prepare()?
            .request()
            .await?;
        upload_small_bytes(quark, &entry.fid, DEVICE_METADATA_FILE_NAME, new_payload).await?;
    }

    // Clear saved auto-unlock key (user must re-save after changing password)
    let _ = clear_saved_key();

    Ok(())
}

pub fn lock_key() {
    *unlocked_key_cell()
        .write()
        .expect("unlocked key lock poisoned") = None;
}

/// Derive a local encryption key from the device_id using SHA-256.
fn device_local_key(device_id: &str) -> [u8; 32] {
    use sha2::Digest;
    let mut hasher = Sha256::new();
    hasher.update(b"quarkdrop-saved-key-v1:");
    hasher.update(device_id.as_bytes());
    let result = hasher.finalize();
    let mut key = [0u8; 32];
    key.copy_from_slice(&result);
    key
}

/// Save the currently unlocked private key to a local file, encrypted with
/// a key derived from the device_id. This is the "intermediate state" —
/// not the password itself, but the unlocked key encrypted for this device.
pub fn save_auto_unlock_key() -> anyhow::Result<()> {
    let secret = load_device_private_key()?;
    let paths = app_paths()?;
    let device_id = fs::read_to_string(&paths.device_id_file)?
        .trim()
        .to_string();
    let local_key = device_local_key(&device_id);
    let cipher = ChaCha20Poly1305::new(Key::from_slice(&local_key));
    let mut nonce_bytes = [0u8; 12];
    OsRng.fill_bytes(&mut nonce_bytes);
    let ciphertext = cipher
        .encrypt(Nonce::from_slice(&nonce_bytes), secret.as_ref())
        .map_err(|e| anyhow::anyhow!("failed to encrypt saved key: {e}"))?;
    let mut blob = Vec::with_capacity(12 + ciphertext.len());
    blob.extend_from_slice(&nonce_bytes);
    blob.extend_from_slice(&ciphertext);
    fs::write(&paths.saved_key_file, blob)?;
    Ok(())
}

/// Try to load and decrypt the saved auto-unlock key. On success sets
/// `UNLOCKED_KEY` and `CLOUD_VERIFY_CACHED` and returns `true`.
pub fn try_auto_unlock() -> anyhow::Result<bool> {
    let paths = app_paths()?;
    if !paths.saved_key_file.exists() {
        return Ok(false);
    }
    let blob = fs::read(&paths.saved_key_file)?;
    anyhow::ensure!(blob.len() > 12, "saved key file is too short");
    let nonce_bytes = &blob[..12];
    let ciphertext = &blob[12..];
    let device_id = fs::read_to_string(&paths.device_id_file)?
        .trim()
        .to_string();
    let local_key = device_local_key(&device_id);
    let cipher = ChaCha20Poly1305::new(Key::from_slice(&local_key));
    let plaintext = cipher
        .decrypt(Nonce::from_slice(nonce_bytes), ciphertext)
        .map_err(|_| anyhow::anyhow!("saved key decryption failed"))?;
    anyhow::ensure!(plaintext.len() == 32, "saved key must be 32 bytes");
    let mut key = [0u8; 32];
    key.copy_from_slice(&plaintext);
    *unlocked_key_cell()
        .write()
        .expect("unlocked key lock poisoned") = Some(key);
    *cloud_verify_cache()
        .write()
        .expect("cloud verify cache poisoned") = Some(true);
    Ok(true)
}

pub fn has_saved_key() -> bool {
    app_paths()
        .map(|p| p.saved_key_file.exists())
        .unwrap_or(false)
}

pub fn clear_saved_key() -> anyhow::Result<()> {
    let paths = app_paths()?;
    let _ = fs::remove_file(&paths.saved_key_file);
    Ok(())
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
        quark.delete(&mailbox.fid).await?;
    }
    Ok(())
}

async fn discover_peer_devices(
    quark: &QuarkPan,
    root_id: &str,
    current_device_id: &str,
) -> anyhow::Result<Vec<DiscoveredPeerDevice>> {
    let excluded_ids = load_excluded_device_ids().unwrap_or_default();
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
        if excluded_ids.contains(&device_id) {
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
        .pdir_fid(parent_folder.to_string())
        .file_name(folder_name.to_string())
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

fn remember_device_profile(local_device: &LocalDevice) -> anyhow::Result<()> {
    let paths = app_paths()?;
    let encrypted_key: EncryptedPrivateKey =
        serde_json::from_slice(&fs::read(&paths.device_private_key_file)?)?;
    fs::create_dir_all(&paths.device_profiles_dir)?;
    let profile = StoredLocalDeviceProfile {
        version: 2,
        device_id: local_device.device_id.clone(),
        device_name: local_device.device_name.clone(),
        encrypted_key,
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

pub fn clear_remembered_devices() -> anyhow::Result<()> {
    let paths = app_paths()?;
    if paths.device_profiles_dir.exists() {
        fs::remove_dir_all(&paths.device_profiles_dir)?;
    }
    Ok(())
}

pub fn clear_local_device_files() -> anyhow::Result<()> {
    let paths = app_paths()?;
    let _ = fs::remove_file(&paths.device_id_file);
    let _ = fs::remove_file(&paths.device_name_file);
    let _ = fs::remove_file(&paths.device_private_key_file);
    let _ = fs::remove_file(&paths.saved_key_file);
    lock_key();
    reset_cloud_verify_cache();
    Ok(())
}

fn excluded_device_ids_path() -> std::io::Result<std::path::PathBuf> {
    let paths = app_paths()?;
    Ok(paths.config_dir.join("excluded_device_ids.json"))
}

pub fn add_excluded_device_id(device_id: &str) -> anyhow::Result<()> {
    let path = excluded_device_ids_path()?;
    let mut ids = load_excluded_device_ids().unwrap_or_default();
    if !ids.contains(&device_id.to_string()) {
        ids.push(device_id.to_string());
        fs::write(&path, serde_json::to_vec(&ids)?)?;
    }
    Ok(())
}

fn load_excluded_device_ids() -> anyhow::Result<Vec<String>> {
    let path = excluded_device_ids_path()?;
    if !path.exists() {
        return Ok(Vec::new());
    }
    let data = fs::read(&path)?;
    Ok(serde_json::from_slice(&data)?)
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
    let paths = app_paths()?;
    let encrypted_key = if paths.device_private_key_file.exists() {
        serde_json::from_slice(&fs::read(&paths.device_private_key_file)?).ok()
    } else {
        None
    };
    let payload = serde_json::to_vec(&DeviceMetadata {
        version: 1,
        device_id: local_device.device_id.clone(),
        device_name: local_device.device_name.clone(),
        public_key: local_public_key_hex()?,
        encrypted_key,
        updated_at: SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|duration| duration.as_millis() as u64)
            .unwrap_or(0),
    })?;
    let existing = list_all_entries(quark, mailbox_id).await?;
    if let Some(old_bak) = existing
        .iter()
        .find(|entry| entry.file_name == DEVICE_METADATA_BAK_FILE_NAME && entry.file)
    {
        quark.delete(&old_bak.fid).await?;
    }
    if let Some(old_current) = existing
        .iter()
        .find(|entry| entry.file_name == DEVICE_METADATA_FILE_NAME && entry.file)
    {
        quark
            .rename()
            .fid(old_current.fid.clone())
            .file_name(DEVICE_METADATA_BAK_FILE_NAME.to_string())
            .prepare()?
            .request()
            .await?;
    }
    upload_small_bytes(quark, mailbox_id, DEVICE_METADATA_FILE_NAME, payload).await?;
    Ok(())
}

async fn read_device_metadata(
    quark: &QuarkPan,
    mailbox_id: &str,
) -> anyhow::Result<Option<DeviceMetadata>> {
    let children = list_all_entries(quark, mailbox_id).await?;
    let metadata_file = if let Some(metadata_file) = children
        .iter()
        .find(|entry| entry.file_name == DEVICE_METADATA_FILE_NAME && entry.file)
    {
        metadata_file.fid.clone()
    } else if let Some(metadata_bak_file) = children
        .iter()
        .find(|entry| entry.file_name == DEVICE_METADATA_BAK_FILE_NAME && entry.file)
    {
        quark
            .rename()
            .fid(metadata_bak_file.fid.clone())
            .file_name(DEVICE_METADATA_FILE_NAME.to_string())
            .prepare()?
            .request()
            .await?;
        metadata_bak_file.fid.clone()
    } else {
        return Ok(None);
    };
    Ok(Some(download_json(quark, &metadata_file).await?))
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
        .pdir_fid(parent_folder_id)
        .file_name(name)
        .size(bytes.len() as u64)
        .md5(md5)
        .sha1(sha1)
        .prepare()
        .await?
    {
        libquarkpan::UploadPrepareResult::RapidUploaded { fid } => Ok(fid),
        libquarkpan::UploadPrepareResult::NeedUpload(session) => {
            let stream =
                stream::once(
                    async move { Ok::<Bytes, libquarkpan::QuarkPanError>(Bytes::from(bytes)) },
                );
            Ok(session.upload_stream(stream).await?.fid)
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

fn derive_key_from_password(password: &str, salt: &[u8]) -> anyhow::Result<[u8; 32]> {
    let mut derived = [0u8; 32];
    Argon2::default()
        .hash_password_into(password.as_bytes(), salt, &mut derived)
        .map_err(|e| anyhow::anyhow!("argon2 key derivation failed: {e}"))?;
    Ok(derived)
}

fn encrypt_private_key(key: &[u8; 32], password: &str) -> anyhow::Result<EncryptedPrivateKey> {
    encrypt_private_key_blob(key.as_ref(), password)
}

fn encrypt_private_key_blob(
    plaintext: &[u8],
    password: &str,
) -> anyhow::Result<EncryptedPrivateKey> {
    let mut salt = [0u8; 16];
    OsRng.fill_bytes(&mut salt);
    let derived = derive_key_from_password(password, &salt)?;
    let cipher = ChaCha20Poly1305::new(Key::from_slice(&derived));
    let mut nonce_bytes = [0u8; 12];
    OsRng.fill_bytes(&mut nonce_bytes);
    let ciphertext = cipher
        .encrypt(Nonce::from_slice(&nonce_bytes), plaintext)
        .map_err(|e| anyhow::anyhow!("encryption failed: {e}"))?;
    Ok(EncryptedPrivateKey {
        version: 1,
        algorithm: "argon2id-chacha20poly1305".to_string(),
        argon2_salt: hex::encode(salt),
        nonce: hex::encode(nonce_bytes),
        ciphertext: hex::encode(ciphertext),
    })
}

fn decrypt_private_key(
    encrypted: &EncryptedPrivateKey,
    password: &str,
) -> anyhow::Result<[u8; 32]> {
    let plaintext = decrypt_private_key_blob(encrypted, password)?;
    anyhow::ensure!(
        plaintext.len() == 32,
        "decrypted key must be 32 bytes, got {}",
        plaintext.len()
    );
    let mut key = [0u8; 32];
    key.copy_from_slice(&plaintext);
    Ok(key)
}

fn decrypt_private_key_blob(
    encrypted: &EncryptedPrivateKey,
    password: &str,
) -> anyhow::Result<Vec<u8>> {
    anyhow::ensure!(
        encrypted.algorithm == "argon2id-chacha20poly1305",
        "unsupported key encryption algorithm `{}`",
        encrypted.algorithm
    );
    let salt = hex::decode(&encrypted.argon2_salt)?;
    let derived = derive_key_from_password(password, &salt)?;
    let cipher = ChaCha20Poly1305::new(Key::from_slice(&derived));
    let nonce_bytes = hex::decode(&encrypted.nonce)?;
    let ciphertext = hex::decode(&encrypted.ciphertext)?;
    cipher
        .decrypt(Nonce::from_slice(&nonce_bytes), ciphertext.as_ref())
        .map_err(|_| anyhow::anyhow!("Incorrect password or corrupted key file."))
}
