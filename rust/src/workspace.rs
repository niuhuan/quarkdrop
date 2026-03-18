use directories::ProjectDirs;
use std::fs;
use std::io;
use std::path::PathBuf;
use std::sync::{OnceLock, RwLock};

#[derive(Clone, Debug)]
pub struct AppPaths {
    pub config_dir: PathBuf,
    pub app_settings_file: PathBuf,
    pub cookie_file: PathBuf,
    pub device_id_file: PathBuf,
    pub device_name_file: PathBuf,
    pub peer_metadata_cache_file: PathBuf,
    pub device_private_key_file: PathBuf,
    pub device_profiles_dir: PathBuf,
    pub saved_key_file: PathBuf,
    pub transfer_history_file: PathBuf,
    pub transfer_db_file: PathBuf,
}

static CONFIG_DIR_OVERRIDE: OnceLock<RwLock<Option<PathBuf>>> = OnceLock::new();

fn config_dir_override() -> &'static RwLock<Option<PathBuf>> {
    CONFIG_DIR_OVERRIDE.get_or_init(|| RwLock::new(None))
}

pub fn set_config_dir_override(config_dir: PathBuf) -> io::Result<()> {
    fs::create_dir_all(&config_dir)?;
    *config_dir_override()
        .write()
        .expect("config dir override lock poisoned") = Some(config_dir);
    Ok(())
}

pub fn app_paths() -> io::Result<AppPaths> {
    let config_dir = config_dir_override()
        .read()
        .expect("config dir override lock poisoned")
        .clone()
        .unwrap_or_else(|| {
            ProjectDirs::from("", "", "quarkdrop")
                .map(|dirs| dirs.config_dir().to_path_buf())
                .unwrap_or_else(|| PathBuf::from("quarkdrop"))
        });
    Ok(AppPaths {
        cookie_file: config_dir.join("cookie.txt"),
        app_settings_file: config_dir.join("app_settings.json"),
        device_id_file: config_dir.join("device_id.txt"),
        device_name_file: config_dir.join("device_name.txt"),
        peer_metadata_cache_file: config_dir.join("peer_metadata_cache.json"),
        device_private_key_file: config_dir.join("device_private_key.json"),
        device_profiles_dir: config_dir.join("device_profiles"),
        saved_key_file: config_dir.join("saved_key.bin"),
        transfer_history_file: config_dir.join("transfer_history.json"),
        transfer_db_file: config_dir.join("transfer_tasks.sqlite3"),
        config_dir,
    })
}
