#![cfg_attr(
    not(any(target_os = "linux", target_os = "macos", target_os = "windows")),
    allow(dead_code)
)]

#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
use crate::api::single_instance_stream::sync_display_to_dart;
#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
use crate::single_instance::SingleInstance;
#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
use flutter_rust_bridge::for_generated::anyhow;
#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
use serde_json::json;
#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
use std::convert::Infallible;
#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
use std::process::exit;
#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
use std::sync::Once;
#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
use warp::Filter;

#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
const SINGLE_NAME: &str = "QUARKDROP_SINGLE_INSTANCE";
#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
const PORT: u16 = 23769;

#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
static mut SINGLE_INSTANCE_VAL: Option<SingleInstance> = None;
#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
static SINGLE_INSTANCE_VAL_LOCK: Once = Once::new();

pub(crate) async fn single() {
    #[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
    match SingleInstance::new(SINGLE_NAME) {
        Ok(instance) => {
            if !instance.is_single() {
                println!("SINGLE_INSTANCE_: Another instance is running.");
                let _ = send_display_signal().await;
                exit(0);
            } else {
                println!("SINGLE_INSTANCE_: This is the first instance.");
                unsafe {
                    SINGLE_INSTANCE_VAL_LOCK.call_once(|| {
                        SINGLE_INSTANCE_VAL = Some(instance);
                    })
                }
                spawn_single_signal().await;
            }
        }
        Err(err) => {
            println!("SINGLE_INSTANCE_: Error: {}", err);
        }
    }
}

#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
async fn send_display_signal() -> anyhow::Result<()> {
    reqwest::get(format!("http://127.0.0.1:{PORT}/display"))
        .await?
        .error_for_status()?
        .text()
        .await?;
    Ok(())
}

#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
async fn spawn_single_signal() {
    tokio::spawn(async {
        let _ = warp::serve(warp::path("display").and_then(display))
            .run(([127, 0, 0, 1], PORT))
            .await;
    });
}

#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
async fn display() -> Result<impl warp::Reply, Infallible> {
    let _ = sync_display_to_dart().await;
    Ok(warp::reply::json(&json!({
        "status": "OK",
    })))
}
