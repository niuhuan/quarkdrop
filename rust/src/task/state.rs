use serde::{Deserialize, Serialize};
use std::io;

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TaskStage {
    Scanning,
    UploadingBlobs,
    UploadingManifest,
    UploadingCommit,
    DownloadingBlobs,
    Verifying,
    CleanupRemote,
    Failed,
    Done,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TaskDirection {
    Send,
    Receive,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct TaskSnapshot {
    pub job_id: String,
    pub stage: TaskStage,
    pub direction: TaskDirection,
    pub local_path: String,
    pub remote_job_folder_id: String,
    #[serde(default)]
    pub remote_mailbox_folder_id: String,
    pub display_name: String,
    pub counterpart_device_id: String,
    pub counterpart_label: String,
    pub size_bytes: u64,
    #[serde(default)]
    pub transferred_bytes: u64,
    #[serde(default)]
    pub protocol_name: String,
    #[serde(default)]
    pub manifest_created_at_unix_ms: u64,
    #[serde(default)]
    pub content_key_seed_hex: String,
    #[serde(default)]
    pub last_error_message: String,
    pub updated_at_unix_ms: u64,
}

impl TaskStage {
    pub fn parse(value: &str) -> io::Result<Self> {
        match value {
            "scanning" => Ok(TaskStage::Scanning),
            "uploading_blobs" => Ok(TaskStage::UploadingBlobs),
            "uploading_manifest" => Ok(TaskStage::UploadingManifest),
            "uploading_commit" => Ok(TaskStage::UploadingCommit),
            "downloading_blobs" => Ok(TaskStage::DownloadingBlobs),
            "verifying" => Ok(TaskStage::Verifying),
            "cleanup_remote" => Ok(TaskStage::CleanupRemote),
            "failed" => Ok(TaskStage::Failed),
            "done" => Ok(TaskStage::Done),
            _ => Err(io::Error::other(format!("unknown task stage `{value}`"))),
        }
    }
}

impl TaskDirection {
    pub fn parse(value: &str) -> io::Result<Self> {
        match value {
            "send" => Ok(TaskDirection::Send),
            "receive" => Ok(TaskDirection::Receive),
            _ => Err(io::Error::other(format!(
                "unknown task direction `{value}`"
            ))),
        }
    }
}
