use flutter_rust_bridge::for_generated::anyhow;
#[cfg(feature = "full-test")]
use std::env;
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

pub(crate) fn generate_fixture_tree(root: &Path) -> anyhow::Result<PathBuf> {
    if root.exists() {
        fs::remove_dir_all(root)?;
    }
    fs::create_dir_all(root.join("payloads"))?;
    fs::create_dir_all(root.join("receive-output"))?;

    write_text(
        &root.join("payloads/single-file/hello-quarkdrop.txt"),
        "QuarkDrop manual test file.\nUse this for the simplest send/receive pass.\n",
    )?;
    write_text(&root.join("payloads/single-file/empty.txt"), "")?;

    write_text(
        &root.join("payloads/project-folder/README.txt"),
        "Project-folder fixture with nested content for recursive send tests.\n",
    )?;
    write_text(
        &root.join("payloads/project-folder/docs/notes.txt"),
        "Nested docs file.\nLine 2.\nLine 3.\n",
    )?;
    write_text(
        &root.join("payloads/project-folder/src/config.json"),
        "{\n  \"name\": \"fixture-project\",\n  \"mode\": \"manual-test\"\n}\n",
    )?;
    write_text(
        &root.join("payloads/project-folder/src/deep/tree/todo.txt"),
        "Deeply nested file for folder restore checks.\n",
    )?;
    write_binary(
        &root.join("payloads/project-folder/bin/blob-1m.bin"),
        1024 * 1024,
        17,
    )?;

    for index in 1..=5 {
        write_text(
            &root.join(format!("payloads/many-small-files/sample-{index:02}.txt")),
            &format!("small fixture file {index}\n"),
        )?;
    }

    write_binary(
        &root.join("payloads/resume-case/resume-8m.bin"),
        8 * 1024 * 1024,
        29,
    )?;
    write_text(
        &root.join("HOW_TO_USE.txt"),
        "Manual test workspace for QuarkDrop.\n\npayloads/single-file       -> quick file send\npayloads/project-folder    -> nested folder send\npayloads/many-small-files  -> many-entry folder send\npayloads/resume-case       -> interrupt/resume transfer test\nreceive-output             -> pick this as the local receive target\n",
    )?;

    Ok(root.to_path_buf())
}

#[cfg(feature = "full-test")]
pub(crate) fn load_full_test_cookie() -> anyhow::Result<String> {
    if let Ok(cookie) = env::var("QUARKDROP_TEST_COOKIE") {
        let normalized = cookie.trim().to_string();
        anyhow::ensure!(
            !normalized.is_empty(),
            "QUARKDROP_TEST_COOKIE is set but empty."
        );
        return Ok(normalized);
    }

    anyhow::bail!("full-test requires QUARKDROP_TEST_COOKIE.")
}

fn write_text(path: &Path, text: &str) -> anyhow::Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(path, text)?;
    Ok(())
}

fn write_binary(path: &Path, size: usize, seed: u8) -> anyhow::Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let mut file = fs::File::create(path)?;
    let chunk = (0..4096)
        .map(|index| seed.wrapping_add((index % 251) as u8))
        .collect::<Vec<_>>();
    let mut remaining = size;
    while remaining > 0 {
        let take = remaining.min(chunk.len());
        file.write_all(&chunk[..take])?;
        remaining -= take;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generates_workspace_fixture_tree() {
        let root = std::env::temp_dir().join(format!("quarkdrop-fixtures-{}", std::process::id()));
        if root.exists() {
            std::fs::remove_dir_all(&root).unwrap();
        }
        let generated = generate_fixture_tree(&root).unwrap();
        assert!(generated
            .join("payloads/single-file/hello-quarkdrop.txt")
            .exists());
        assert!(generated
            .join("payloads/project-folder/bin/blob-1m.bin")
            .exists());
        assert!(generated
            .join("payloads/resume-case/resume-8m.bin")
            .exists());
        std::fs::remove_dir_all(&root).unwrap();
    }
}
