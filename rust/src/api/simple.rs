use crate::auth::session;
use crate::task::store;
use crate::workspace;
use flutter_rust_bridge::for_generated::anyhow;
use std::sync::Once;

static INIT_APP_ONCE: Once = Once::new();
#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
static INIT_SINGLE_INSTANCE_ONCE: Once = Once::new();

#[flutter_rust_bridge::frb(init)]
pub fn init_app() -> anyhow::Result<()> {
    INIT_APP_ONCE.call_once(flutter_rust_bridge::setup_default_user_utils);
    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn configure_app(config_dir: String) -> anyhow::Result<()> {
    crate::device::reset_runtime_state();
    workspace::set_config_dir_override(config_dir.into())?;
    session::initialize_session_from_disk()?;
    let _ = store::mark_interrupted_tasks_failed();
    Ok(())
}

pub async fn init_single_instance() -> anyhow::Result<()> {
    #[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
    {
        if INIT_SINGLE_INSTANCE_ONCE.is_completed() {
            return Ok(());
        }
        crate::single::single().await;
        INIT_SINGLE_INSTANCE_ONCE.call_once(|| {});
    }
    Ok(())
}
