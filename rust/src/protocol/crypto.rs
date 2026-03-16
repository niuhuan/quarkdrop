use chacha20poly1305::aead::{Aead, KeyInit};
use chacha20poly1305::{ChaCha20Poly1305, Key, Nonce};
use flutter_rust_bridge::for_generated::anyhow;
use hkdf::Hkdf;
use rand::rngs::OsRng;
use rand::RngCore;
use serde::{Deserialize, Serialize};
use sha2::Sha256;
use x25519_dalek::{PublicKey, StaticSecret};

pub const CONTENT_CIPHER_NAME: &str = "framed-chacha20poly1305-v1";
pub const ENVELOPE_CIPHER_NAME: &str = "sealed-x25519-chacha20poly1305-v1";
pub const BLOB_FRAME_PLAIN_BYTES: usize = 1024 * 1024;
pub const CHACHA_TAG_BYTES: usize = 16;

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct EncryptedEnvelope {
    pub version: u32,
    pub algorithm: String,
    #[serde(default)]
    pub receiver_device_id: String,
    pub sender_ephemeral_public_key: String,
    pub nonce: String,
    pub ciphertext: String,
}

pub fn random_key_material() -> [u8; 32] {
    let mut value = [0u8; 32];
    OsRng.fill_bytes(&mut value);
    value
}

pub fn seal_for_receiver(
    receiver_public_key_hex: &str,
    receiver_device_id: &str,
    context: &[u8],
    plaintext: &[u8],
) -> anyhow::Result<EncryptedEnvelope> {
    let receiver_public = parse_public_key(receiver_public_key_hex)?;
    let ephemeral_secret = StaticSecret::random_from_rng(OsRng);
    let ephemeral_public = PublicKey::from(&ephemeral_secret);
    let shared_secret = ephemeral_secret.diffie_hellman(&receiver_public);
    let cipher = envelope_cipher(shared_secret.as_bytes(), context)?;
    let mut nonce_bytes = [0u8; 12];
    OsRng.fill_bytes(&mut nonce_bytes);
    let ciphertext = cipher.encrypt(Nonce::from_slice(&nonce_bytes), plaintext)?;
    Ok(EncryptedEnvelope {
        version: 1,
        algorithm: ENVELOPE_CIPHER_NAME.to_string(),
        receiver_device_id: receiver_device_id.to_string(),
        sender_ephemeral_public_key: hex::encode(ephemeral_public.as_bytes()),
        nonce: hex::encode(nonce_bytes),
        ciphertext: hex::encode(ciphertext),
    })
}

pub fn open_with_private_key(
    envelope: &EncryptedEnvelope,
    receiver_private_key: &[u8; 32],
    context: &[u8],
) -> anyhow::Result<Vec<u8>> {
    anyhow::ensure!(
        envelope.algorithm == ENVELOPE_CIPHER_NAME,
        "unsupported envelope algorithm `{}`",
        envelope.algorithm
    );
    let sender_public = parse_public_key(&envelope.sender_ephemeral_public_key)?;
    let receiver_secret = StaticSecret::from(*receiver_private_key);
    let shared_secret = receiver_secret.diffie_hellman(&sender_public);
    let cipher = envelope_cipher(shared_secret.as_bytes(), context)?;
    let nonce = decode_array::<12>(&envelope.nonce, "envelope nonce")?;
    let ciphertext = hex::decode(&envelope.ciphertext)?;
    Ok(cipher.decrypt(Nonce::from_slice(&nonce), ciphertext.as_ref())?)
}

pub fn derive_file_key(content_key_seed: &[u8; 32], entry_id: &str) -> anyhow::Result<[u8; 32]> {
    let hkdf = Hkdf::<Sha256>::new(Some(b"quarkdrop-file-key"), content_key_seed);
    let mut key = [0u8; 32];
    hkdf.expand(format!("entry:{entry_id}:content").as_bytes(), &mut key)
        .map_err(|_| anyhow::anyhow!("failed to derive file key"))?;
    Ok(key)
}

pub fn encrypt_blob_frame(
    file_key: &[u8; 32],
    entry_id: &str,
    blob_index: usize,
    frame_index: u64,
    plaintext: &[u8],
) -> anyhow::Result<Vec<u8>> {
    let nonce = derive_blob_nonce(file_key, entry_id, blob_index, frame_index)?;
    let cipher = ChaCha20Poly1305::new(Key::from_slice(file_key));
    Ok(cipher.encrypt(Nonce::from_slice(&nonce), plaintext)?)
}

pub fn decrypt_blob_frame(
    file_key: &[u8; 32],
    entry_id: &str,
    blob_index: usize,
    frame_index: u64,
    ciphertext: &[u8],
) -> anyhow::Result<Vec<u8>> {
    let nonce = derive_blob_nonce(file_key, entry_id, blob_index, frame_index)?;
    let cipher = ChaCha20Poly1305::new(Key::from_slice(file_key));
    Ok(cipher.decrypt(Nonce::from_slice(&nonce), ciphertext)?)
}

fn derive_blob_nonce(
    file_key: &[u8; 32],
    entry_id: &str,
    blob_index: usize,
    frame_index: u64,
) -> anyhow::Result<[u8; 12]> {
    let hkdf = Hkdf::<Sha256>::new(Some(b"quarkdrop-blob-nonce"), file_key);
    let mut nonce = [0u8; 12];
    hkdf.expand(
        format!("entry:{entry_id}:blob:{blob_index}:frame:{frame_index}").as_bytes(),
        &mut nonce,
    )
    .map_err(|_| anyhow::anyhow!("failed to derive blob nonce"))?;
    Ok(nonce)
}

fn envelope_cipher(shared_secret: &[u8], context: &[u8]) -> anyhow::Result<ChaCha20Poly1305> {
    let hkdf = Hkdf::<Sha256>::new(Some(b"quarkdrop-envelope-key"), shared_secret);
    let mut key = [0u8; 32];
    hkdf.expand(context, &mut key)
        .map_err(|_| anyhow::anyhow!("failed to derive envelope key"))?;
    Ok(ChaCha20Poly1305::new(Key::from_slice(&key)))
}

fn parse_public_key(hex_value: &str) -> anyhow::Result<PublicKey> {
    let bytes = decode_array::<32>(hex_value, "public key")?;
    Ok(PublicKey::from(bytes))
}

fn decode_array<const N: usize>(hex_value: &str, label: &str) -> anyhow::Result<[u8; N]> {
    let bytes = hex::decode(hex_value)?;
    anyhow::ensure!(
        bytes.len() == N,
        "invalid {label} length: expected {N} bytes, got {}",
        bytes.len()
    );
    let mut array = [0u8; N];
    array.copy_from_slice(&bytes);
    Ok(array)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn envelope_roundtrip_works() {
        let receiver_secret = [5u8; 32];
        let receiver_public = PublicKey::from(&StaticSecret::from(receiver_secret));
        let envelope = seal_for_receiver(
            &hex::encode(receiver_public.as_bytes()),
            "receiver",
            b"manifest",
            b"hello world",
        )
        .unwrap();
        let plaintext = open_with_private_key(&envelope, &receiver_secret, b"manifest").unwrap();
        assert_eq!(plaintext, b"hello world");
    }

    #[test]
    fn blob_frame_roundtrip_works() {
        let file_key = [9u8; 32];
        let ciphertext = encrypt_blob_frame(&file_key, "entry_demo", 2, 7, b"payload").unwrap();
        let plaintext = decrypt_blob_frame(&file_key, "entry_demo", 2, 7, &ciphertext).unwrap();
        assert_eq!(plaintext, b"payload");
    }
}
