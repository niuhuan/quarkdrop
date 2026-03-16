use crate::protocol::crypto::{self, EncryptedEnvelope};
use flutter_rust_bridge::for_generated::anyhow;
use serde::{Deserialize, Serialize};

pub const MANIFEST_FILE_NAME: &str = "manifest.enc";
pub const MANIFEST_CONTEXT: &[u8] = b"quarkdrop-manifest-v1";

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ManifestEntryKind {
    File,
    Directory,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct ManifestEntry {
    pub entry_id: String,
    pub kind: ManifestEntryKind,
    pub path: Vec<String>,
    #[serde(default)]
    pub size: u64,
    #[serde(default)]
    pub sha256_plain: String,
    #[serde(default)]
    pub cipher: String,
    pub blob_ids: Vec<String>,
    #[serde(default)]
    pub blob_sizes: Vec<u64>,
    #[serde(default)]
    pub blob_plain_sizes: Vec<u64>,
    #[serde(default)]
    pub blob_sha256_cipher: Vec<String>,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct JobManifest {
    pub version: u32,
    pub job_id: String,
    #[serde(default)]
    pub created_at: u64,
    #[serde(default)]
    pub sender_device_id: String,
    #[serde(default)]
    pub sender_device_name: String,
    #[serde(default)]
    pub receiver_device_id: String,
    #[serde(default)]
    pub receiver_device_name: String,
    #[serde(default)]
    pub root_kind: String,
    pub root_name: String,
    #[serde(default)]
    pub content_key_seed_hex: String,
    pub entries: Vec<ManifestEntry>,
}

pub fn encode_for_receiver(
    manifest: &JobManifest,
    receiver_public_key_hex: &str,
) -> anyhow::Result<Vec<u8>> {
    let plaintext = serde_json::to_vec(manifest)?;
    let envelope = crypto::seal_for_receiver(
        receiver_public_key_hex,
        &manifest.receiver_device_id,
        MANIFEST_CONTEXT,
        &plaintext,
    )?;
    Ok(serde_json::to_vec(&envelope)?)
}

pub fn decode_from_bytes(
    bytes: &[u8],
    receiver_private_key: &[u8; 32],
) -> anyhow::Result<JobManifest> {
    if let Ok(plain) = serde_json::from_slice::<JobManifest>(bytes) {
        return Ok(plain);
    }
    let envelope: EncryptedEnvelope = serde_json::from_slice(bytes)?;
    let plaintext =
        crypto::open_with_private_key(&envelope, receiver_private_key, MANIFEST_CONTEXT)?;
    Ok(serde_json::from_slice(&plaintext)?)
}
