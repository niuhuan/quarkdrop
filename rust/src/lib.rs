pub mod api;
mod auth;
mod device;
mod frb_generated;
#[cfg(all(test, feature = "full-test"))]
mod full_test;
mod preferences;
mod protocol;
mod receive;
mod send;
mod single;
mod single_instance;
mod task;
#[cfg(any(test, feature = "full-test"))]
mod test_support;
mod workspace;
