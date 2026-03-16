use crate::protocol::crypto::{self, EncryptedEnvelope};
use flutter_rust_bridge::for_generated::anyhow;
use serde::{Deserialize, Serialize};

pub const COMMIT_FILE_NAME: &str = "commit.ok.enc";
pub const COMMIT_CONTEXT: &[u8] = b"quarkdrop-commit-v1";

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct CommitMarker {
    pub job_id: String,
    pub manifest_digest: String,
    pub protocol_version: u32,
}

pub fn encode_for_receiver(
    commit: &CommitMarker,
    receiver_device_id: &str,
    receiver_public_key_hex: &str,
) -> anyhow::Result<Vec<u8>> {
    let plaintext = serde_json::to_vec(commit)?;
    let envelope = crypto::seal_for_receiver(
        receiver_public_key_hex,
        receiver_device_id,
        COMMIT_CONTEXT,
        &plaintext,
    )?;
    Ok(serde_json::to_vec(&envelope)?)
}

pub fn decode_from_bytes(
    bytes: &[u8],
    receiver_private_key: &[u8; 32],
) -> anyhow::Result<CommitMarker> {
    if let Ok(plain) = serde_json::from_slice::<CommitMarker>(bytes) {
        return Ok(plain);
    }
    let envelope: EncryptedEnvelope = serde_json::from_slice(bytes)?;
    let plaintext = crypto::open_with_private_key(&envelope, receiver_private_key, COMMIT_CONTEXT)?;
    Ok(serde_json::from_slice(&plaintext)?)
}
