use crate::auth::session::{self, CookieSource};
use crate::device;
use crate::preferences;
use crate::protocol::commit::COMMIT_FILE_NAME;
use crate::protocol::manifest::MANIFEST_FILE_NAME;
use crate::receive;
use crate::send;
use crate::task::state::{TaskDirection, TaskSnapshot, TaskStage};
use crate::task::store::{
    clear_completed_task_snapshots, find_task_snapshot, load_task_snapshots, remove_task_snapshot,
};
use flutter_rust_bridge::for_generated::anyhow;
use libquarkpan::QuarkPan;

#[derive(Clone, Debug)]
pub enum AuthState {
    LoginRequired,
    NeedCreatePassword,
    NeedVerifyPassword,
    Ready,
}

#[derive(Clone, Debug)]
pub enum TransferDirection {
    Send,
    Receive,
}

#[derive(Clone, Debug)]
pub enum TransferStage {
    Preparing,
    UploadingBlobs,
    UploadingManifest,
    UploadingCommit,
    DownloadingBlobs,
    Verifying,
    CleanupRemote,
    Failed,
    Done,
}

#[derive(Clone, Debug)]
pub struct ProtocolNames {
    pub manifest_name: String,
    pub commit_name: String,
}

#[derive(Clone, Debug)]
pub struct DeviceSnapshot {
    pub device_id: String,
    pub device_name: String,
    pub auth_source: String,
    pub mailbox_status_label: String,
    pub mailbox_summary: String,
    pub inbox_job_count: i32,
}

#[derive(Clone, Debug)]
pub struct InboxPreview {
    pub id: String,
    pub sender: String,
    pub root_name: String,
    pub summary: String,
    pub size_label: String,
    pub received_at_label: String,
    pub is_ready: bool,
}

#[derive(Clone, Debug)]
pub struct PeerDevice {
    pub device_id: String,
    pub mailbox_folder_id: String,
    pub label: String,
    pub subtitle: String,
}

#[derive(Clone, Debug)]
pub struct RememberedDevice {
    pub device_id: String,
    pub device_name: String,
    pub is_current: bool,
}

#[derive(Clone, Debug)]
pub struct TransferPreview {
    pub id: String,
    pub title: String,
    pub subtitle: String,
    pub size_label: String,
    pub progress: f64,
    pub stage: TransferStage,
    pub direction: TransferDirection,
}

#[derive(Clone, Debug)]
pub struct ShellSnapshot {
    pub auth_state: AuthState,
    pub protocol_names: ProtocolNames,
    pub device_snapshot: DeviceSnapshot,
    pub inbox_previews: Vec<InboxPreview>,
    pub peer_devices: Vec<PeerDevice>,
    pub transfer_previews: Vec<TransferPreview>,
}

pub async fn shell_snapshot() -> anyhow::Result<ShellSnapshot> {
    let local_device = device::load_or_create_local_device()?;
    let cookie_session = session::current_session();
    let protocol_names = ProtocolNames {
        manifest_name: MANIFEST_FILE_NAME.to_string(),
        commit_name: COMMIT_FILE_NAME.to_string(),
    };
    let transfer_previews = load_transfer_previews();
    let mut device_snapshot = DeviceSnapshot {
        device_id: local_device.device_id.clone(),
        device_name: local_device.device_name.clone(),
        auth_source: auth_source_label(cookie_session.source).to_string(),
        mailbox_status_label: "Login required".to_string(),
        mailbox_summary: "Authenticate with Quark to prepare this device mailbox.".to_string(),
        inbox_job_count: 0,
    };

    if !cookie_session.is_configured() {
        return Ok(ShellSnapshot {
            auth_state: AuthState::LoginRequired,
            protocol_names,
            device_snapshot,
            inbox_previews: Vec::new(),
            peer_devices: Vec::new(),
            transfer_previews,
        });
    }

    let quark = match QuarkPan::builder()
        .cookie(cookie_session.raw_cookie.clone())
        .prepare()
    {
        Ok(quark) => quark,
        Err(error) => {
            device_snapshot.mailbox_summary =
                format!("Saved session needs login again before QuarkDrop can open the remote mailbox: {error}");
            return Ok(ShellSnapshot {
                auth_state: AuthState::LoginRequired,
                protocol_names,
                device_snapshot,
                inbox_previews: Vec::new(),
                peer_devices: Vec::new(),
                transfer_previews,
            });
        }
    };

    // Check cloud password status before accessing mailbox
    let has_verify = device::has_cloud_password_verify_cached(&quark)
        .await
        .map_err(|error| {
            anyhow::anyhow!(
                "Failed to load QuarkDrop cloud password state before initialization: {error}"
            )
        })?;
    let key_unlocked = device::is_key_unlocked();
    if !has_verify {
        device_snapshot.mailbox_status_label = "Password setup required".to_string();
        device_snapshot.mailbox_summary =
            "Set a cloud password to encrypt and protect your device keys.".to_string();
        return Ok(ShellSnapshot {
            auth_state: AuthState::NeedCreatePassword,
            protocol_names,
            device_snapshot,
            inbox_previews: Vec::new(),
            peer_devices: Vec::new(),
            transfer_previews,
        });
    }
    if !key_unlocked {
        // Try auto-unlock with saved key before prompting for password
        if device::try_auto_unlock().unwrap_or(false) {
            // Key unlocked successfully from saved key — fall through to ready
        } else {
            device_snapshot.mailbox_status_label = "Password required".to_string();
            device_snapshot.mailbox_summary =
                "Enter your cloud password to unlock this device.".to_string();
            return Ok(ShellSnapshot {
                auth_state: AuthState::NeedVerifyPassword,
                protocol_names,
                device_snapshot,
                inbox_previews: Vec::new(),
                peer_devices: Vec::new(),
                transfer_previews,
            });
        }
    }

    let mailbox_state = match device::ensure_mailbox_state(
        &quark,
        &protocol_names.manifest_name,
        &protocol_names.commit_name,
        &local_device,
    )
    .await
    {
        Ok(mailbox_state) => mailbox_state,
        Err(error) => {
            device_snapshot.mailbox_summary =
                format!("Reconnect to Quark to refresh this device mailbox: {error}");
            return Ok(ShellSnapshot {
                auth_state: AuthState::LoginRequired,
                protocol_names,
                device_snapshot,
                inbox_previews: Vec::new(),
                peer_devices: Vec::new(),
                transfer_previews,
            });
        }
    };
    device_snapshot.mailbox_status_label = mailbox_state.mailbox_status_label;
    device_snapshot.mailbox_summary = mailbox_state.mailbox_summary;
    device_snapshot.inbox_job_count = mailbox_state.inbox_job_count;

    Ok(ShellSnapshot {
        auth_state: AuthState::Ready,
        protocol_names,
        device_snapshot,
        inbox_previews: mailbox_state
            .inbox_previews
            .into_iter()
            .map(|preview| InboxPreview {
                id: preview.id,
                sender: preview.sender,
                root_name: preview.root_name,
                summary: preview.summary,
                size_label: preview.size_label,
                received_at_label: preview.received_at_label,
                is_ready: preview.is_ready,
            })
            .collect(),
        peer_devices: mailbox_state
            .peer_devices
            .into_iter()
            .map(|peer| PeerDevice {
                device_id: peer.device_id,
                mailbox_folder_id: peer.mailbox_folder_id,
                label: peer.label,
                subtitle: peer.subtitle,
            })
            .collect(),
        transfer_previews,
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn quark_login_url() -> String {
    "https://pan.quark.cn".to_string()
}

#[flutter_rust_bridge::frb(sync)]
pub fn validate_cookie_string(cookie: String) -> bool {
    QuarkPan::builder().cookie(cookie).prepare().is_ok()
}

fn store_validated_cookie(cookie: String, source: CookieSource) -> anyhow::Result<bool> {
    anyhow::ensure!(
        validate_cookie_string(cookie.clone()),
        "The provided cookie is not accepted by QuarkPan.",
    );

    device::reset_cloud_verify_cache();
    session::save_cookie(cookie, source)?;
    Ok(true)
}

#[flutter_rust_bridge::frb(sync)]
pub fn save_cookie_string(cookie: String) -> anyhow::Result<bool> {
    store_validated_cookie(cookie, CookieSource::ManualInput)
}

#[flutter_rust_bridge::frb(sync)]
pub fn save_webview_cookie_string(cookie: String) -> anyhow::Result<bool> {
    store_validated_cookie(cookie, CookieSource::InAppWebView)
}

#[flutter_rust_bridge::frb(sync)]
pub fn clear_cookie_session() -> anyhow::Result<()> {
    session::clear_cookie()?;
    Ok(())
}

pub async fn sign_out(delete_remote_mailbox: bool) -> anyhow::Result<()> {
    let local_device = device::load_or_create_local_device()?;
    device::add_excluded_device_id(&local_device.device_id)?;
    let cookie_session = session::current_session();
    if cookie_session.is_configured() && delete_remote_mailbox {
        let quark = QuarkPan::builder()
            .cookie(cookie_session.raw_cookie)
            .prepare()?;
        device::remove_local_mailbox(&quark, &local_device).await?;
    }
    device::clear_remembered_devices()?;
    device::clear_local_device_files()?;
    session::clear_cookie()?;
    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn save_device_name(name: String) -> anyhow::Result<String> {
    device::save_device_name(name)
}

#[flutter_rust_bridge::frb(sync)]
pub fn remembered_devices() -> anyhow::Result<Vec<RememberedDevice>> {
    Ok(device::list_remembered_devices()?
        .into_iter()
        .map(|device| RememberedDevice {
            device_id: device.device_id,
            device_name: device.device_name,
            is_current: device.is_current,
        })
        .collect())
}

#[flutter_rust_bridge::frb(sync)]
pub fn restore_remembered_device(device_id: String) -> anyhow::Result<String> {
    Ok(device::restore_remembered_device(device_id)?.device_name)
}

#[flutter_rust_bridge::frb(sync)]
pub fn bind_cloud_device(device_id: String) -> anyhow::Result<()> {
    device::bind_cloud_device(device_id)
}

#[flutter_rust_bridge::frb(sync)]
pub fn preferred_locale() -> anyhow::Result<String> {
    Ok(preferences::preferred_locale()?.unwrap_or_default())
}

#[flutter_rust_bridge::frb(sync)]
pub fn theme_mode() -> anyhow::Result<String> {
    preferences::theme_mode()
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_theme_mode(mode: String) -> anyhow::Result<String> {
    preferences::set_theme_mode(mode)
}

#[flutter_rust_bridge::frb(sync)]
pub fn save_preferred_locale(code: String) -> anyhow::Result<String> {
    preferences::save_preferred_locale(code)
}

#[flutter_rust_bridge::frb(sync)]
pub fn clear_preferred_locale() -> anyhow::Result<()> {
    preferences::clear_preferred_locale()
}

#[flutter_rust_bridge::frb(sync)]
pub fn preferred_download_dir() -> anyhow::Result<String> {
    Ok(preferences::preferred_download_dir()?.unwrap_or_default())
}

#[flutter_rust_bridge::frb(sync)]
pub fn save_preferred_download_dir(path: String) -> anyhow::Result<String> {
    preferences::save_preferred_download_dir(path)
}

#[flutter_rust_bridge::frb(sync)]
pub fn clear_preferred_download_dir() -> anyhow::Result<()> {
    preferences::clear_preferred_download_dir()
}

#[flutter_rust_bridge::frb(sync)]
pub fn auto_receive_enabled() -> anyhow::Result<bool> {
    preferences::auto_receive_enabled()
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_auto_receive_enabled(enabled: bool) -> anyhow::Result<bool> {
    preferences::set_auto_receive_enabled(enabled)
}

#[flutter_rust_bridge::frb(sync)]
pub fn navigate_after_transfer() -> anyhow::Result<bool> {
    preferences::navigate_after_transfer()
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_navigate_after_transfer(enabled: bool) -> anyhow::Result<bool> {
    preferences::set_navigate_after_transfer(enabled)
}

#[flutter_rust_bridge::frb(sync)]
pub fn poll_interval_seconds() -> anyhow::Result<u32> {
    preferences::poll_interval_seconds()
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_poll_interval_seconds(seconds: u32) -> anyhow::Result<u32> {
    preferences::set_poll_interval_seconds(seconds)
}

#[flutter_rust_bridge::frb(sync)]
pub fn max_concurrent_uploads() -> anyhow::Result<u32> {
    preferences::max_concurrent_uploads()
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_max_concurrent_uploads(count: u32) -> anyhow::Result<u32> {
    preferences::set_max_concurrent_uploads(count)
}

#[flutter_rust_bridge::frb(sync)]
pub fn max_concurrent_downloads() -> anyhow::Result<u32> {
    preferences::max_concurrent_downloads()
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_max_concurrent_downloads(count: u32) -> anyhow::Result<u32> {
    preferences::set_max_concurrent_downloads(count)
}

#[flutter_rust_bridge::frb(sync)]
pub fn keep_screen_on_during_transfer() -> anyhow::Result<bool> {
    preferences::keep_screen_on_during_transfer()
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_keep_screen_on_during_transfer(enabled: bool) -> anyhow::Result<bool> {
    preferences::set_keep_screen_on_during_transfer(enabled)
}

#[flutter_rust_bridge::frb(sync)]
pub fn minimize_to_tray() -> anyhow::Result<bool> {
    preferences::minimize_to_tray()
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_minimize_to_tray(enabled: bool) -> anyhow::Result<bool> {
    preferences::set_minimize_to_tray(enabled)
}

#[flutter_rust_bridge::frb(sync)]
pub fn peer_discovery_interval_minutes() -> anyhow::Result<u32> {
    preferences::peer_discovery_interval_minutes()
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_peer_discovery_interval_minutes(minutes: u32) -> anyhow::Result<u32> {
    preferences::set_peer_discovery_interval_minutes(minutes)
}

pub async fn create_cloud_password(password: String) -> anyhow::Result<()> {
    let cookie_session = session::current_session();
    anyhow::ensure!(cookie_session.is_configured(), "Login required.");
    let quark = QuarkPan::builder()
        .cookie(cookie_session.raw_cookie)
        .prepare()?;
    device::create_cloud_password(&quark, &password).await
}

pub async fn verify_cloud_password(password: String) -> anyhow::Result<()> {
    let cookie_session = session::current_session();
    anyhow::ensure!(cookie_session.is_configured(), "Login required.");
    let quark = QuarkPan::builder()
        .cookie(cookie_session.raw_cookie)
        .prepare()?;
    device::verify_cloud_password(&quark, &password).await
}

pub async fn change_cloud_password(
    old_password: String,
    new_password: String,
) -> anyhow::Result<()> {
    let cookie_session = session::current_session();
    anyhow::ensure!(cookie_session.is_configured(), "Login required.");
    let quark = QuarkPan::builder()
        .cookie(cookie_session.raw_cookie)
        .prepare()?;
    device::change_cloud_password(&quark, &old_password, &new_password).await
}

#[flutter_rust_bridge::frb(sync)]
pub fn open_data_folder() -> anyhow::Result<()> {
    #[cfg(not(any(target_os = "ios", target_os = "android")))]
    {
        let paths = crate::workspace::app_paths()?;
        opener::open(&paths.config_dir)
            .map_err(|e| anyhow::anyhow!("Failed to open data folder: {e}"))?;
    }
    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn save_auto_unlock_key() -> anyhow::Result<()> {
    device::save_auto_unlock_key()
}

#[flutter_rust_bridge::frb(sync)]
pub fn has_saved_key() -> bool {
    device::has_saved_key()
}

#[flutter_rust_bridge::frb(sync)]
pub fn clear_saved_key() -> anyhow::Result<()> {
    device::clear_saved_key()
}

pub async fn send_local_path(
    peer_mailbox_folder_id: String,
    peer_device_id: String,
    peer_label: String,
    source_path: String,
) -> anyhow::Result<String> {
    let cookie_session = session::current_session();
    anyhow::ensure!(
        cookie_session.is_configured(),
        "Authenticate with Quark before sending a file.",
    );

    let quark = QuarkPan::builder()
        .cookie(cookie_session.raw_cookie)
        .prepare()?;
    let local_device = device::load_or_create_local_device()?;
    send::send_local_path(
        &quark,
        &local_device,
        &peer_mailbox_folder_id,
        &peer_device_id,
        &peer_label,
        &source_path,
    )
    .await
}

pub async fn receive_job(job_folder_id: String, output_dir: String) -> anyhow::Result<String> {
    let cookie_session = session::current_session();
    anyhow::ensure!(
        cookie_session.is_configured(),
        "Authenticate with Quark before receiving a job.",
    );

    let quark = QuarkPan::builder()
        .cookie(cookie_session.raw_cookie)
        .prepare()?;
    receive::receive_job(&quark, &job_folder_id, &output_dir).await
}

pub async fn reject_inbox_job(job_folder_id: String) -> anyhow::Result<()> {
    let cookie_session = session::current_session();
    anyhow::ensure!(
        cookie_session.is_configured(),
        "Authenticate with Quark before rejecting a job.",
    );

    let quark = QuarkPan::builder()
        .cookie(cookie_session.raw_cookie)
        .prepare()?;
    match quark.delete(&job_folder_id).await {
        Ok(()) => Ok(()),
        Err(libquarkpan::QuarkPanError::Api { status, .. }) if status == 404 => Ok(()),
        Err(error) => Err(error.into()),
    }
}

pub async fn resume_task(job_id: String) -> anyhow::Result<String> {
    let cookie_session = session::current_session();
    anyhow::ensure!(
        cookie_session.is_configured(),
        "Authenticate with Quark before resuming a task.",
    );
    let task = find_task_snapshot(&job_id)?
        .ok_or_else(|| anyhow::anyhow!("Saved task `{job_id}` not found."))?;
    anyhow::ensure!(
        !matches!(task.stage, TaskStage::Done),
        "Task `{job_id}` is already completed."
    );

    let quark = QuarkPan::builder()
        .cookie(cookie_session.raw_cookie)
        .prepare()?;
    match task.direction {
        TaskDirection::Send => {
            let local_device = device::load_or_create_local_device()?;
            send::resume_send_task(&quark, &local_device, &task).await
        }
        TaskDirection::Receive => receive::resume_receive_task(&quark, &task).await,
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn clear_completed_transfers() -> anyhow::Result<i32> {
    let removed = clear_completed_task_snapshots()?;
    Ok(i32::try_from(removed).unwrap_or(i32::MAX))
}

pub async fn delete_transfer(job_id: String) -> anyhow::Result<()> {
    let task = find_task_snapshot(&job_id)?
        .ok_or_else(|| anyhow::anyhow!("Saved task `{job_id}` not found."))?;

    if !task.remote_job_folder_id.trim().is_empty() {
        let cookie_session = session::current_session();
        anyhow::ensure!(
            cookie_session.is_configured(),
            "Authenticate with Quark before deleting the remote transfer job.",
        );
        let quark = QuarkPan::builder()
            .cookie(cookie_session.raw_cookie)
            .prepare()?;
        match quark.delete(&task.remote_job_folder_id).await {
            Ok(()) => {}
            Err(libquarkpan::QuarkPanError::Api { status, .. }) if status == 404 => {}
            Err(error) => return Err(error.into()),
        }
    }

    remove_task_snapshot(&job_id)?;
    Ok(())
}

fn auth_source_label(source: CookieSource) -> &'static str {
    match source {
        CookieSource::Unset => "Unset",
        CookieSource::ManualInput => "Manual cookie",
        CookieSource::InAppWebView => "Embedded WebView",
        CookieSource::Persisted => "Persisted session",
    }
}

fn load_transfer_previews() -> Vec<TransferPreview> {
    load_task_snapshots()
        .unwrap_or_default()
        .into_iter()
        .take(12)
        .map(map_task_snapshot)
        .collect()
}

fn map_task_snapshot(task: TaskSnapshot) -> TransferPreview {
    let stage = match task.stage {
        TaskStage::Scanning => TransferStage::Preparing,
        TaskStage::UploadingBlobs => TransferStage::UploadingBlobs,
        TaskStage::UploadingManifest => TransferStage::UploadingManifest,
        TaskStage::UploadingCommit => TransferStage::UploadingCommit,
        TaskStage::DownloadingBlobs => TransferStage::DownloadingBlobs,
        TaskStage::Verifying => TransferStage::Verifying,
        TaskStage::CleanupRemote => TransferStage::CleanupRemote,
        TaskStage::Failed => TransferStage::Failed,
        TaskStage::Done => TransferStage::Done,
    };
    let direction = match task.direction {
        TaskDirection::Send => TransferDirection::Send,
        TaskDirection::Receive => TransferDirection::Receive,
    };
    let base_subtitle = match task.stage {
        TaskStage::Done => format!(
            "Delivered {} to {}.",
            size_label(task.size_bytes),
            task.counterpart_label
        ),
        TaskStage::UploadingCommit => {
            format!("Finalizing relay package for {}.", task.counterpart_label)
        }
        TaskStage::UploadingManifest => {
            format!("Uploading manifest for {}.", task.counterpart_label)
        }
        TaskStage::UploadingBlobs => format!("Uploading file body to {}.", task.counterpart_label),
        TaskStage::Scanning => format!("Preparing {} for upload.", task.display_name),
        TaskStage::DownloadingBlobs => {
            format!("Downloading relay payload from {}.", task.counterpart_label)
        }
        TaskStage::Verifying => format!("Verifying {}.", task.display_name),
        TaskStage::CleanupRemote => "Cleaning up remote relay objects.".to_string(),
        TaskStage::Failed => {
            let reason = task.last_error_message.trim();
            if reason.is_empty() {
                "Transfer stopped before completion.".to_string()
            } else {
                format!("Failed: {reason}")
            }
        }
    };
    let subtitle = if matches!(task.stage, TaskStage::Done | TaskStage::Failed) {
        base_subtitle
    } else {
        format!("{base_subtitle} Saved in the local JSON task file for recovery.")
    };

    TransferPreview {
        id: task.job_id,
        title: task.display_name,
        subtitle,
        size_label: if task.size_bytes > 0 {
            size_label(task.size_bytes)
        } else {
            String::new()
        },
        progress: match task.stage {
            TaskStage::Scanning => 0.1,
            TaskStage::UploadingBlobs => 0.55,
            TaskStage::UploadingManifest => 0.8,
            TaskStage::UploadingCommit => 0.95,
            TaskStage::DownloadingBlobs => 0.45,
            TaskStage::Verifying => 0.9,
            TaskStage::CleanupRemote => 0.98,
            TaskStage::Failed => 0.0,
            TaskStage::Done => 1.0,
        },
        stage,
        direction,
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
pub async fn remove_peer_device(peer_device_id: String) -> anyhow::Result<()> {
    let cookie_session = session::current_session();
    let quark = QuarkPan::builder()
        .cookie(cookie_session.raw_cookie)
        .prepare()?;
    
    device::remove_peer_mailbox(&quark, &peer_device_id).await
}
