use crate::task::state::TaskSnapshot;
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

pub fn clear_completed_task_snapshots() -> io::Result<usize> {
    let mut snapshots = load_task_snapshots()?;
    let original_len = snapshots.len();
    snapshots.retain(|snapshot| snapshot.stage != crate::task::state::TaskStage::Done);
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
