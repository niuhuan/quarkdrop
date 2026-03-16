use crate::workspace::app_paths;
use std::fs;
use std::io;
use std::sync::{OnceLock, RwLock};

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum CookieSource {
    Unset,
    ManualInput,
    InAppWebView,
    Persisted,
}

#[derive(Clone, Debug, Default)]
pub struct CookieSession {
    pub raw_cookie: String,
    pub source: CookieSource,
}

impl CookieSession {
    pub fn is_configured(&self) -> bool {
        !self.raw_cookie.trim().is_empty()
    }
}

impl Default for CookieSource {
    fn default() -> Self {
        Self::Unset
    }
}

static COOKIE_SESSION: OnceLock<RwLock<CookieSession>> = OnceLock::new();

fn session_store() -> &'static RwLock<CookieSession> {
    COOKIE_SESSION.get_or_init(|| RwLock::new(CookieSession::default()))
}

pub fn current_session() -> CookieSession {
    session_store()
        .read()
        .expect("cookie session lock poisoned")
        .clone()
}

pub fn initialize_session_from_disk() -> io::Result<()> {
    let paths = app_paths()?;
    if !paths.cookie_file.exists() {
        return Ok(());
    }

    let raw_cookie = fs::read_to_string(&paths.cookie_file)?;
    let raw_cookie = raw_cookie.trim().to_string();
    if raw_cookie.is_empty() {
        match fs::remove_file(&paths.cookie_file) {
            Ok(()) => {}
            Err(error) if error.kind() == io::ErrorKind::NotFound => {}
            Err(error) => return Err(error),
        }
        return Ok(());
    }

    let mut session = session_store()
        .write()
        .expect("cookie session lock poisoned");
    session.raw_cookie = raw_cookie;
    session.source = CookieSource::Persisted;
    Ok(())
}

pub fn save_cookie(raw_cookie: String, source: CookieSource) -> io::Result<()> {
    let normalized = raw_cookie.trim().to_string();
    if normalized.is_empty() {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "cookie cannot be empty",
        ));
    }

    let paths = app_paths()?;
    fs::create_dir_all(&paths.config_dir)?;
    fs::write(&paths.cookie_file, format!("{normalized}\n"))?;

    let mut session = session_store()
        .write()
        .expect("cookie session lock poisoned");
    session.raw_cookie = normalized;
    session.source = source;
    Ok(())
}

pub fn clear_cookie() -> io::Result<()> {
    let paths = app_paths()?;
    match fs::remove_file(&paths.cookie_file) {
        Ok(()) => {}
        Err(error) if error.kind() == io::ErrorKind::NotFound => {}
        Err(error) => return Err(error),
    }

    let mut session = session_store()
        .write()
        .expect("cookie session lock poisoned");
    *session = CookieSession::default();
    Ok(())
}
