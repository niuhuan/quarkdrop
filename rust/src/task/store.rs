use crate::task::state::{TaskSnapshot, TaskStage};
use crate::workspace::app_paths;
use std::fs;
use std::io;

pub fn load_task_snapshots() -> io::Result<Vec<TaskSnapshot>> {
    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;
    migrate_legacy_sqlite_to_json()?;

    if !paths.transfer_history_file.exists() {
        return Ok(Vec::new());
    }
    let raw = fs::read_to_string(&paths.transfer_history_file)?;
    if raw.trim().is_empty() {
        return Ok(Vec::new());
    }

    let mut snapshots: Vec<TaskSnapshot> = serde_json::from_str(&raw).map_err(io::Error::other)?;
    snapshots.sort_by(|left, right| {
        right
            .updated_at_unix_ms
            .cmp(&left.updated_at_unix_ms)
            .then_with(|| left.job_id.cmp(&right.job_id))
    });
    Ok(snapshots)
}

pub fn upsert_task_snapshot(snapshot: &TaskSnapshot) -> io::Result<()> {
    let mut snapshots = load_task_snapshots().unwrap_or_default();
    if let Some(existing) = snapshots
        .iter_mut()
        .find(|item| item.job_id == snapshot.job_id)
    {
        *existing = snapshot.clone();
    } else {
        snapshots.push(snapshot.clone());
    }
    save_task_snapshots(&snapshots)?;
    Ok(())
}

pub fn find_task_snapshot(job_id: &str) -> io::Result<Option<TaskSnapshot>> {
    Ok(load_task_snapshots()?
        .into_iter()
        .find(|snapshot| snapshot.job_id == job_id))
}

pub fn remove_task_snapshot(job_id: &str) -> io::Result<bool> {
    let mut snapshots = load_task_snapshots()?;
    let original_len = snapshots.len();
    snapshots.retain(|snapshot| snapshot.job_id != job_id);
    if snapshots.len() == original_len {
        return Ok(false);
    }
    save_task_snapshots(&snapshots)?;
    Ok(true)
}

pub fn mark_interrupted_tasks_failed() -> io::Result<usize> {
    let mut snapshots = load_task_snapshots()?;
    let mut count = 0usize;
    for snapshot in &mut snapshots {
        match snapshot.stage {
            TaskStage::Done | TaskStage::Failed => {}
            _ => {
                snapshot.stage = TaskStage::Failed;
                snapshot.last_error_message =
                    "Transfer was interrupted by app shutdown.".to_string();
                count += 1;
            }
        }
    }
    if count > 0 {
        save_task_snapshots(&snapshots)?;
    }
    Ok(count)
}

pub fn clear_completed_task_snapshots() -> io::Result<usize> {
    let mut snapshots = load_task_snapshots()?;
    let original_len = snapshots.len();
    snapshots.retain(|snapshot| snapshot.stage != TaskStage::Done);
    let removed = original_len.saturating_sub(snapshots.len());
    if removed > 0 {
        save_task_snapshots(&snapshots)?;
    }
    Ok(removed)
}

pub fn save_task_snapshots(snapshots: &[TaskSnapshot]) -> io::Result<()> {
    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;
    let mut ordered = snapshots.to_vec();
    ordered.sort_by(|left, right| {
        right
            .updated_at_unix_ms
            .cmp(&left.updated_at_unix_ms)
            .then_with(|| left.job_id.cmp(&right.job_id))
    });
    let encoded = serde_json::to_string_pretty(&ordered).map_err(io::Error::other)?;
    fs::write(&paths.transfer_history_file, encoded)?;
    Ok(())
}

fn migrate_legacy_sqlite_to_json() -> io::Result<()> {
    let paths = app_paths()?;
    if paths.transfer_history_file.exists() || !paths.transfer_db_file.exists() {
        return Ok(());
    }

    let connection =
        rusqlite::Connection::open(&paths.transfer_db_file).map_err(io::Error::other)?;
    let mut statement = connection
        .prepare(
            "SELECT job_id, stage, direction, local_path, remote_job_folder_id, display_name,
                    counterpart_device_id, counterpart_label, size_bytes, updated_at_unix_ms
             FROM transfer_tasks
             ORDER BY updated_at_unix_ms DESC, job_id ASC",
        )
        .map_err(io::Error::other)?;
    let rows = statement
        .query_map([], |row| {
            let stage: String = row.get(1)?;
            let direction: String = row.get(2)?;
            Ok(TaskSnapshot {
                job_id: row.get(0)?,
                stage: crate::task::state::TaskStage::parse(&stage).map_err(|error| {
                    rusqlite::Error::FromSqlConversionFailure(
                        1,
                        rusqlite::types::Type::Text,
                        Box::new(error),
                    )
                })?,
                direction: crate::task::state::TaskDirection::parse(&direction).map_err(
                    |error| {
                        rusqlite::Error::FromSqlConversionFailure(
                            2,
                            rusqlite::types::Type::Text,
                            Box::new(error),
                        )
                    },
                )?,
                local_path: row.get(3)?,
                remote_job_folder_id: row.get(4)?,
                remote_mailbox_folder_id: String::new(),
                display_name: row.get(5)?,
                counterpart_device_id: row.get(6)?,
                counterpart_label: row.get(7)?,
                size_bytes: row.get::<_, i64>(8)? as u64,
                transferred_bytes: 0,
                protocol_name: String::new(),
                manifest_created_at_unix_ms: 0,
                content_key_seed_hex: String::new(),
                last_error_message: String::new(),
                updated_at_unix_ms: row.get::<_, i64>(9)? as u64,
            })
        })
        .map_err(io::Error::other)?;
    let mut snapshots = Vec::new();
    for row in rows {
        snapshots.push(row.map_err(io::Error::other)?);
    }
    save_task_snapshots(&snapshots)?;
    let _ = fs::remove_file(&paths.transfer_db_file);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::task::state::{TaskDirection, TaskStage};
    use crate::workspace;
    use uuid::Uuid;

    fn make_snapshot(
        job_id: &str,
        stage: TaskStage,
        direction: TaskDirection,
        updated_at: u64,
    ) -> TaskSnapshot {
        TaskSnapshot {
            job_id: job_id.to_string(),
            stage,
            direction,
            local_path: "/tmp/test-file.txt".to_string(),
            remote_job_folder_id: "remote-folder-id".to_string(),
            remote_mailbox_folder_id: "mailbox-folder-id".to_string(),
            display_name: "test-file.txt".to_string(),
            counterpart_device_id: "peer-device".to_string(),
            counterpart_label: "Test Peer".to_string(),
            size_bytes: 1024 * 1024,
            transferred_bytes: 512 * 1024,
            protocol_name: "encrypted-sized-v1".to_string(),
            manifest_created_at_unix_ms: 1000000,
            content_key_seed_hex: String::new(),
            last_error_message: String::new(),
            updated_at_unix_ms: updated_at,
        }
    }

    /// Simulates a full app restart lifecycle:
    /// 1. Tasks stuck in various in-progress stages survive raw reload
    /// 2. `mark_interrupted_tasks_failed` (called at startup) moves them to Failed
    /// 3. Done and already-Failed tasks are left untouched
    /// 4. Stuck tasks can also be individually deleted or bulk-cleared
    #[test]
    fn stuck_task_lifecycle() {
        let tmp = std::env::temp_dir().join(format!("quarkdrop-store-test-{}", Uuid::new_v4()));
        workspace::set_config_dir_override(tmp.clone()).unwrap();

        // --- Phase 1: create tasks in various stages ---
        let uploading =
            make_snapshot("upload-001", TaskStage::UploadingBlobs, TaskDirection::Send, 2000);
        let downloading = make_snapshot(
            "download-001",
            TaskStage::DownloadingBlobs,
            TaskDirection::Receive,
            1900,
        );
        let scanning =
            make_snapshot("scan-001", TaskStage::Scanning, TaskDirection::Send, 1850);
        let failed =
            make_snapshot("failed-001", TaskStage::Failed, TaskDirection::Send, 1800);
        let done =
            make_snapshot("done-001", TaskStage::Done, TaskDirection::Receive, 1700);

        upsert_task_snapshot(&uploading).unwrap();
        upsert_task_snapshot(&downloading).unwrap();
        upsert_task_snapshot(&scanning).unwrap();
        upsert_task_snapshot(&failed).unwrap();
        upsert_task_snapshot(&done).unwrap();

        // Raw reload: all stages are preserved as-is
        let raw = load_task_snapshots().unwrap();
        assert_eq!(raw.len(), 5);
        assert_eq!(
            raw.iter().find(|s| s.job_id == "upload-001").unwrap().stage,
            TaskStage::UploadingBlobs
        );

        // --- Phase 2: simulate startup recovery ---
        let recovered = mark_interrupted_tasks_failed().unwrap();
        assert_eq!(recovered, 3); // uploading + downloading + scanning

        let after_recovery = load_task_snapshots().unwrap();
        for snapshot in &after_recovery {
            match snapshot.job_id.as_str() {
                "upload-001" | "download-001" | "scan-001" => {
                    assert_eq!(snapshot.stage, TaskStage::Failed);
                    assert!(!snapshot.last_error_message.is_empty());
                }
                "failed-001" => {
                    assert_eq!(snapshot.stage, TaskStage::Failed);
                    assert!(snapshot.last_error_message.is_empty());
                }
                "done-001" => assert_eq!(snapshot.stage, TaskStage::Done),
                other => panic!("unexpected job_id: {other}"),
            }
        }

        // --- Phase 3: delete one, clear completed ---
        remove_task_snapshot("upload-001").unwrap();
        let cleared = clear_completed_task_snapshots().unwrap();
        assert_eq!(cleared, 1); // done-001

        let final_list = load_task_snapshots().unwrap();
        assert_eq!(final_list.len(), 3);
        assert!(final_list.iter().all(|s| s.stage == TaskStage::Failed));

        fs::remove_dir_all(tmp).unwrap();
    }
}
