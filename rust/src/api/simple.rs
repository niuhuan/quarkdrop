use crate::auth::session;
use crate::workspace;
use flutter_rust_bridge::for_generated::anyhow;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() -> anyhow::Result<()> {
    flutter_rust_bridge::setup_default_user_utils();
    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn configure_app(config_dir: String) -> anyhow::Result<()> {
    workspace::set_config_dir_override(config_dir.into())?;
    session::initialize_session_from_disk()?;
    Ok(())
}
