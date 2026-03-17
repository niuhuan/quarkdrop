use crate::workspace::app_paths;
use flutter_rust_bridge::for_generated::anyhow;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;

#[derive(Debug, Serialize, Deserialize)]
struct AppSettings {
    #[serde(default)]
    preferred_locale: Option<String>,
    #[serde(default)]
    preferred_download_dir: Option<String>,
    #[serde(default)]
    auto_receive_enabled: bool,
    #[serde(default = "default_true")]
    navigate_after_transfer: bool,
    #[serde(default = "default_poll_interval")]
    poll_interval_seconds: u32,
    #[serde(default = "default_transfer_parallelism")]
    max_concurrent_uploads: u32,
    #[serde(default = "default_transfer_parallelism")]
    max_concurrent_downloads: u32,
    #[serde(default = "default_true")]
    keep_screen_on_during_transfer: bool,
    #[serde(default)]
    minimize_to_tray: bool,
    #[serde(default = "default_peer_discovery_interval")]
    peer_discovery_interval_minutes: u32,
}

fn default_true() -> bool {
    true
}

fn default_poll_interval() -> u32 {
    30
}

fn default_transfer_parallelism() -> u32 {
    2
}

fn default_peer_discovery_interval() -> u32 {
    10
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            preferred_locale: None,
            preferred_download_dir: None,
            auto_receive_enabled: false,
            navigate_after_transfer: true,
            poll_interval_seconds: 30,
            max_concurrent_uploads: 2,
            max_concurrent_downloads: 2,
            keep_screen_on_during_transfer: true,
            minimize_to_tray: false,
            peer_discovery_interval_minutes: 10,
        }
    }
}

pub fn preferred_locale() -> anyhow::Result<Option<String>> {
    Ok(load_settings()?
        .preferred_locale
        .map(|value| value.trim().to_string())
        .filter(|value| !value.is_empty()))
}

pub fn save_preferred_locale(code: String) -> anyhow::Result<String> {
    let normalized = code.trim().to_string();
    anyhow::ensure!(!normalized.is_empty(), "Locale cannot be empty.");
    let mut settings = load_settings()?;
    settings.preferred_locale = Some(normalized.clone());
    save_settings(&settings)?;
    Ok(normalized)
}

pub fn clear_preferred_locale() -> anyhow::Result<()> {
    let mut settings = load_settings()?;
    settings.preferred_locale = None;
    save_settings(&settings)?;
    Ok(())
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

pub fn navigate_after_transfer() -> anyhow::Result<bool> {
    Ok(load_settings()?.navigate_after_transfer)
}

pub fn set_navigate_after_transfer(enabled: bool) -> anyhow::Result<bool> {
    let mut settings = load_settings()?;
    settings.navigate_after_transfer = enabled;
    save_settings(&settings)?;
    Ok(enabled)
}

pub fn poll_interval_seconds() -> anyhow::Result<u32> {
    Ok(load_settings()?.poll_interval_seconds)
}

pub fn set_poll_interval_seconds(seconds: u32) -> anyhow::Result<u32> {
    let clamped = seconds.max(5).min(300);
    let mut settings = load_settings()?;
    settings.poll_interval_seconds = clamped;
    save_settings(&settings)?;
    Ok(clamped)
}

pub fn max_concurrent_uploads() -> anyhow::Result<u32> {
    Ok(load_settings()?.max_concurrent_uploads.max(1).min(8))
}

pub fn set_max_concurrent_uploads(count: u32) -> anyhow::Result<u32> {
    let clamped = count.max(1).min(8);
    let mut settings = load_settings()?;
    settings.max_concurrent_uploads = clamped;
    save_settings(&settings)?;
    Ok(clamped)
}

pub fn max_concurrent_downloads() -> anyhow::Result<u32> {
    Ok(load_settings()?.max_concurrent_downloads.max(1).min(8))
}

pub fn set_max_concurrent_downloads(count: u32) -> anyhow::Result<u32> {
    let clamped = count.max(1).min(8);
    let mut settings = load_settings()?;
    settings.max_concurrent_downloads = clamped;
    save_settings(&settings)?;
    Ok(clamped)
}

pub fn keep_screen_on_during_transfer() -> anyhow::Result<bool> {
    Ok(load_settings()?.keep_screen_on_during_transfer)
}

pub fn set_keep_screen_on_during_transfer(enabled: bool) -> anyhow::Result<bool> {
    let mut settings = load_settings()?;
    settings.keep_screen_on_during_transfer = enabled;
    save_settings(&settings)?;
    Ok(enabled)
}

pub fn minimize_to_tray() -> anyhow::Result<bool> {
    Ok(load_settings()?.minimize_to_tray)
}

pub fn set_minimize_to_tray(enabled: bool) -> anyhow::Result<bool> {
    let mut settings = load_settings()?;
    settings.minimize_to_tray = enabled;
    save_settings(&settings)?;
    Ok(enabled)
}

pub fn peer_discovery_interval_minutes() -> anyhow::Result<u32> {
    Ok(load_settings()?.peer_discovery_interval_minutes)
}

pub fn set_peer_discovery_interval_minutes(minutes: u32) -> anyhow::Result<u32> {
    let clamped = minutes.max(1).min(1440);
    let mut settings = load_settings()?;
    settings.peer_discovery_interval_minutes = clamped;
    save_settings(&settings)?;
    Ok(clamped)
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
