use crate::workspace::app_paths;
use flutter_rust_bridge::for_generated::anyhow;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

#[derive(Debug, Default, Serialize, Deserialize)]
struct AppSettings {
    #[serde(default)]
    preferred_download_dir: Option<String>,
    #[serde(default)]
    auto_receive_enabled: bool,
}

pub fn preferred_download_dir() -> anyhow::Result<Option<String>> {
    Ok(load_settings()?
        .preferred_download_dir
        .filter(|value| !value.is_empty()))
}

pub fn save_preferred_download_dir(path: String) -> anyhow::Result<String> {
    let normalized = path.trim().to_string();
    anyhow::ensure!(!normalized.is_empty(), "Download folder cannot be empty.");
    anyhow::ensure!(
        Path::new(&normalized).exists(),
        "Download folder does not exist."
    );
    anyhow::ensure!(
        Path::new(&normalized).is_dir(),
        "Download folder must be a directory."
    );
    let mut settings = load_settings()?;
    settings.preferred_download_dir = Some(normalized.clone());
    save_settings(&settings)?;
    Ok(normalized)
}

pub fn clear_preferred_download_dir() -> anyhow::Result<()> {
    let mut settings = load_settings()?;
    settings.preferred_download_dir = None;
    save_settings(&settings)?;
    Ok(())
}

pub fn auto_receive_enabled() -> anyhow::Result<bool> {
    Ok(load_settings()?.auto_receive_enabled)
}

pub fn set_auto_receive_enabled(enabled: bool) -> anyhow::Result<bool> {
    let mut settings = load_settings()?;
    settings.auto_receive_enabled = enabled;
    save_settings(&settings)?;
    Ok(enabled)
}

fn load_settings() -> anyhow::Result<AppSettings> {
    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;
    if !paths.app_settings_file.exists() {
        return Ok(AppSettings::default());
    }
    let raw = fs::read_to_string(&paths.app_settings_file)?;
    if raw.trim().is_empty() {
        return Ok(AppSettings::default());
    }
    Ok(serde_json::from_str(&raw)?)
}

fn save_settings(settings: &AppSettings) -> anyhow::Result<()> {
    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;
    fs::write(
        &paths.app_settings_file,
        serde_json::to_string_pretty(settings)?,
    )?;
    Ok(())
}
