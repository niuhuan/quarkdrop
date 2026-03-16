use crate::auth::session::{self, CookieSource};
use crate::device::{self, DiscoveredPeerDevice, LocalDevice};
use crate::protocol::commit::COMMIT_FILE_NAME;
use crate::protocol::manifest::MANIFEST_FILE_NAME;
use crate::receive;
use crate::send;
use crate::task::state::TaskStage;
use crate::task::store::find_task_snapshot;
use crate::test_support::{generate_fixture_tree, load_full_test_cookie};
use crate::workspace;
use flutter_rust_bridge::for_generated::anyhow;
use libquarkpan::{QuarkEntry, QuarkPan};
use std::path::{Path, PathBuf};
use tokio::fs;
use tokio::time::{sleep, Duration};
use uuid::Uuid;

struct Actor {
    config_dir: PathBuf,
    quark: QuarkPan,
    device: LocalDevice,
}

#[tokio::test(flavor = "multi_thread")]
async fn full_test_send_receive_resume_cleanup() -> anyhow::Result<()> {
    let cookie = load_full_test_cookie()?;
    let root = std::env::temp_dir().join(format!("quarkdrop-full-test-{}", Uuid::new_v4()));
    let fixture_root = root.join("fixtures");
    let sender_config = root.join("sender-config");
    let receiver_config = root.join("receiver-config");
    let download_root = root.join("downloads");
    fs::create_dir_all(&download_root).await?;
    generate_fixture_tree(&fixture_root)?;

    let single_file = fixture_root.join("payloads/single-file/hello-quarkdrop.txt");
    let resume_file = fixture_root.join("payloads/resume-case/resume-8m.bin");
    let folder_source = fixture_root.join("payloads/project-folder");

    let receiver = prepare_actor(&receiver_config, "QuarkDrop Full Test Receiver", &cookie).await?;
    let sender = prepare_actor(&sender_config, "QuarkDrop Full Test Sender", &cookie).await?;
    let receiver_peer = find_peer(&sender, &cookie, &receiver.device.device_id).await?;

    activate_actor(&sender, &cookie)?;
    let normal_job_id = send::send_local_path(
        &sender.quark,
        &sender.device,
        &receiver_peer.mailbox_folder_id,
        &receiver_peer.device_id,
        &receiver_peer.label,
        &single_file.to_string_lossy(),
    )
    .await?;
    assert_stage(&normal_job_id, TaskStage::Done)?;

    activate_actor(&sender, &cookie)?;
    let partial_upload = send::stage_partial_send_for_test(
        &sender.quark,
        &sender.device,
        &receiver_peer.mailbox_folder_id,
        &receiver_peer.device_id,
        &receiver_peer.label,
        &resume_file.to_string_lossy(),
    )
    .await?;
    assert_stage(&partial_upload.job_id, TaskStage::UploadingBlobs)?;
    let resumed_upload_job_id =
        send::resume_send_task(&sender.quark, &sender.device, &partial_upload).await?;
    assert_eq!(resumed_upload_job_id, partial_upload.job_id);
    assert_stage(&resumed_upload_job_id, TaskStage::Done)?;

    activate_actor(&sender, &cookie)?;
    let folder_job_id = send::send_local_path(
        &sender.quark,
        &sender.device,
        &receiver_peer.mailbox_folder_id,
        &receiver_peer.device_id,
        &receiver_peer.label,
        &folder_source.to_string_lossy(),
    )
    .await?;
    assert_stage(&folder_job_id, TaskStage::Done)?;

    let normal_job_folder_id =
        wait_for_job_folder(&receiver, &normal_job_id, Some(MANIFEST_FILE_NAME), &cookie).await?;
    activate_actor(&receiver, &cookie)?;
    let normal_download_dir = download_root.join("normal");
    fs::create_dir_all(&normal_download_dir).await?;
    let downloaded_normal_job_id = receive::receive_job(
        &receiver.quark,
        &normal_job_folder_id,
        &normal_download_dir.to_string_lossy(),
    )
    .await?;
    assert_eq!(downloaded_normal_job_id, normal_job_id);
    assert_files_equal(
        &single_file,
        &normal_download_dir.join("hello-quarkdrop.txt"),
    )
    .await?;
    wait_for_job_absence(&receiver, &normal_job_id, &cookie).await?;

    let resume_job_folder_id = wait_for_job_folder(
        &receiver,
        &resumed_upload_job_id,
        Some(MANIFEST_FILE_NAME),
        &cookie,
    )
    .await?;
    activate_actor(&receiver, &cookie)?;
    let resume_download_dir = download_root.join("resume");
    fs::create_dir_all(&resume_download_dir).await?;
    seed_partial_download(
        &resume_file,
        &resume_download_dir.join("resume-8m.bin"),
        1024 * 1024,
    )
    .await?;
    let downloaded_resume_job_id = receive::receive_job(
        &receiver.quark,
        &resume_job_folder_id,
        &resume_download_dir.to_string_lossy(),
    )
    .await?;
    assert_eq!(downloaded_resume_job_id, resumed_upload_job_id);
    assert_files_equal(&resume_file, &resume_download_dir.join("resume-8m.bin")).await?;
    wait_for_job_absence(&receiver, &resumed_upload_job_id, &cookie).await?;

    let folder_job_folder_id =
        wait_for_job_folder(&receiver, &folder_job_id, Some(COMMIT_FILE_NAME), &cookie).await?;
    activate_actor(&receiver, &cookie)?;
    let folder_download_dir = download_root.join("folder");
    fs::create_dir_all(&folder_download_dir).await?;
    let downloaded_folder_job_id = receive::receive_job(
        &receiver.quark,
        &folder_job_folder_id,
        &folder_download_dir.to_string_lossy(),
    )
    .await?;
    assert_eq!(downloaded_folder_job_id, folder_job_id);
    assert_files_equal(
        &folder_source.join("README.txt"),
        &folder_download_dir.join("project-folder/README.txt"),
    )
    .await?;
    assert_files_equal(
        &folder_source.join("docs/notes.txt"),
        &folder_download_dir.join("project-folder/docs/notes.txt"),
    )
    .await?;
    wait_for_job_absence(&receiver, &folder_job_id, &cookie).await?;

    activate_actor(&sender, &cookie)?;
    let delete_remote_job_id = send::send_local_path(
        &sender.quark,
        &sender.device,
        &receiver_peer.mailbox_folder_id,
        &receiver_peer.device_id,
        &receiver_peer.label,
        &single_file.to_string_lossy(),
    )
    .await?;
    let delete_remote_folder_id = wait_for_job_folder(
        &receiver,
        &delete_remote_job_id,
        Some(COMMIT_FILE_NAME),
        &cookie,
    )
    .await?;
    sender.quark.delete_file(&delete_remote_folder_id).await?;
    wait_for_job_absence(&receiver, &delete_remote_job_id, &cookie).await?;

    fs::remove_file(normal_download_dir.join("hello-quarkdrop.txt")).await?;
    assert!(!normal_download_dir.join("hello-quarkdrop.txt").exists());
    fs::remove_file(resume_download_dir.join("resume-8m.bin")).await?;
    assert!(!resume_download_dir.join("resume-8m.bin").exists());
    fs::remove_dir_all(folder_download_dir.join("project-folder")).await?;
    assert!(!folder_download_dir.join("project-folder").exists());

    cleanup_mailbox(&sender, &cookie).await?;
    cleanup_mailbox(&receiver, &cookie).await?;
    if root.exists() {
        fs::remove_dir_all(&root).await?;
    }
    Ok(())
}

async fn prepare_actor(
    config_dir: &Path,
    device_name: &str,
    cookie: &str,
) -> anyhow::Result<Actor> {
    activate_config(config_dir, cookie)?;
    device::save_device_name(device_name.to_string())?;
    let quark = QuarkPan::builder().cookie(cookie).prepare()?;
    let device = device::load_or_create_local_device()?;
    let _ =
        device::ensure_mailbox_state(&quark, MANIFEST_FILE_NAME, COMMIT_FILE_NAME, &device).await?;
    Ok(Actor {
        config_dir: config_dir.to_path_buf(),
        quark,
        device,
    })
}

fn activate_actor(actor: &Actor, cookie: &str) -> anyhow::Result<()> {
    activate_config(&actor.config_dir, cookie)
}

fn activate_config(config_dir: &Path, cookie: &str) -> anyhow::Result<()> {
    workspace::set_config_dir_override(config_dir.to_path_buf())?;
    session::save_cookie(cookie.to_string(), CookieSource::ManualInput)?;
    Ok(())
}

async fn find_peer(
    actor: &Actor,
    cookie: &str,
    target_device_id: &str,
) -> anyhow::Result<DiscoveredPeerDevice> {
    activate_actor(actor, cookie)?;
    let mailbox = device::ensure_mailbox_state(
        &actor.quark,
        MANIFEST_FILE_NAME,
        COMMIT_FILE_NAME,
        &actor.device,
    )
    .await?;
    mailbox
        .peer_devices
        .into_iter()
        .find(|peer| peer.device_id == target_device_id)
        .ok_or_else(|| anyhow::anyhow!("could not discover peer device `{target_device_id}`"))
}

fn assert_stage(job_id: &str, expected: TaskStage) -> anyhow::Result<()> {
    let snapshot = find_task_snapshot(job_id)?
        .ok_or_else(|| anyhow::anyhow!("task snapshot `{job_id}` not found"))?;
    anyhow::ensure!(
        snapshot.stage == expected,
        "task `{job_id}` expected stage {:?}, got {:?}",
        expected,
        snapshot.stage
    );
    Ok(())
}

async fn wait_for_job_folder(
    receiver: &Actor,
    job_id: &str,
    required_child_name: Option<&str>,
    cookie: &str,
) -> anyhow::Result<String> {
    let job_name = format!("job_{job_id}");
    let mailbox_id = mailbox_folder_id(receiver, cookie).await?;
    for _ in 0..30 {
        activate_actor(receiver, cookie)?;
        let entries = list_all_entries(&receiver.quark, &mailbox_id).await?;
        if let Some(job) = entries
            .iter()
            .find(|entry| entry.dir && entry.file_name == job_name)
        {
            if let Some(child_name) = required_child_name {
                let children = list_all_entries(&receiver.quark, &job.fid).await?;
                if children.iter().any(|entry| entry.file_name == child_name) {
                    return Ok(job.fid.clone());
                }
            } else {
                return Ok(job.fid.clone());
            }
        }
        sleep(Duration::from_secs(1)).await;
    }
    anyhow::bail!("timed out waiting for remote job `{job_name}`")
}

async fn wait_for_job_absence(receiver: &Actor, job_id: &str, cookie: &str) -> anyhow::Result<()> {
    let job_name = format!("job_{job_id}");
    let mailbox_id = mailbox_folder_id(receiver, cookie).await?;
    for _ in 0..30 {
        activate_actor(receiver, cookie)?;
        let entries = list_all_entries(&receiver.quark, &mailbox_id).await?;
        if entries.iter().all(|entry| entry.file_name != job_name) {
            return Ok(());
        }
        sleep(Duration::from_secs(1)).await;
    }
    anyhow::bail!("timed out waiting for remote job `{job_name}` to disappear")
}

async fn mailbox_folder_id(actor: &Actor, cookie: &str) -> anyhow::Result<String> {
    activate_actor(actor, cookie)?;
    let root_id = ensure_child_folder(&actor.quark, "0", "QuarkDrop").await?;
    ensure_child_folder(
        &actor.quark,
        &root_id,
        &format!("device_{}", actor.device.device_id),
    )
    .await
}

async fn ensure_child_folder(
    quark: &QuarkPan,
    parent_id: &str,
    name: &str,
) -> anyhow::Result<String> {
    let entries = list_all_entries(quark, parent_id).await?;
    entries
        .into_iter()
        .find(|entry| entry.dir && entry.file_name == name)
        .map(|entry| entry.fid)
        .ok_or_else(|| anyhow::anyhow!("folder `{name}` not found under `{parent_id}`"))
}

async fn list_all_entries(quark: &QuarkPan, folder_id: &str) -> anyhow::Result<Vec<QuarkEntry>> {
    let mut entries = Vec::new();
    let mut page_no = 1;
    loop {
        let page = quark
            .list()
            .folder_id(folder_id.to_string())
            .page(page_no)
            .size(100)
            .prepare()?
            .request()
            .await?;
        let count = page.entries.len();
        entries.extend(page.entries);
        if count < 100 {
            break;
        }
        page_no += 1;
    }
    Ok(entries)
}

async fn assert_files_equal(expected: &Path, actual: &Path) -> anyhow::Result<()> {
    let expected_bytes = fs::read(expected).await?;
    let actual_bytes = fs::read(actual).await?;
    anyhow::ensure!(
        expected_bytes == actual_bytes,
        "file mismatch: expected `{}`, actual `{}`",
        expected.display(),
        actual.display()
    );
    Ok(())
}

async fn seed_partial_download(
    source: &Path,
    destination: &Path,
    bytes: usize,
) -> anyhow::Result<()> {
    let source_bytes = fs::read(source).await?;
    let parent = destination
        .parent()
        .ok_or_else(|| anyhow::anyhow!("destination has no parent"))?;
    fs::create_dir_all(parent).await?;
    let part_path = destination.with_extension("quarkdrop.part");
    fs::write(&part_path, &source_bytes[..bytes.min(source_bytes.len())]).await?;
    Ok(())
}

async fn cleanup_mailbox(actor: &Actor, cookie: &str) -> anyhow::Result<()> {
    if let Ok(mailbox_id) = mailbox_folder_id(actor, cookie).await {
        activate_actor(actor, cookie)?;
        let _ = actor.quark.delete_file(&mailbox_id).await;
    }
    Ok(())
}
