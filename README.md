# QuarkDrop

[![pub version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/niuhuan/libquark)

English | [简体中文](./README-zh_Hans.md)

---

QuarkDrop is a cross-platform encrypted relay file transfer app powered by **Quark Drive** (夸克网盘).  
Files are end-to-end encrypted before being uploaded as a temporary relay package.  
The recipient device downloads and decrypts the package, then the cloud copy is automatically cleaned up.

No self-hosted server required — Quark Drive is used as the relay medium.

## Features

- **Send files & folders** to any other device signed in with the same Quark account
- **Inbox** — receive relay packages sent by peer devices, or reject them to delete from cloud
- **Transfer history** — per-task progress, size, stage and one-tap resume for failed jobs
- **Auto-receive** — automatically download incoming files to a chosen directory
- **End-to-end encryption** — AES-GCM per-chunk encryption; cloud stores only ciphertext
- **Cloud password** — device keys are encrypted with a user-set password
- **Multi-platform** — Android · iOS · Windows · macOS · Linux
- **Background transfers** — files are queued and transferred in the background
- **Configurable concurrency** — set how many uploads/downloads run in parallel
- **Launch at startup** (desktop)

## Platform Support

| Android | iOS | Windows | macOS | Linux |
|:-------:|:---:|:-------:|:-----:|:-----:|
|   ✔     |  ✔  |    ✔    |   ✔   |   ✔   |

## Getting Started

1. Install QuarkDrop on at least two devices.
2. Sign in to both devices with the same Quark account.
3. Set a cloud password on the first device — the second device will be asked to verify it.
4. Both devices appear in each other's **Send** screen.
5. Pick a file or folder, choose the target device, tap **Send Batch**.

## Screen Shoots

<img src="images/send.png" />

<img src="images/transfer.png" width="50%" />

## Architecture

### Principle

- Each device owns a private mailbox folder in the Quark Drive.
- Sending writes an encrypted relay package into the recipient device's mailbox folder.
- The recipient polls for new packages and downloads them automatically (or manually from the **Inbox**).
- After a successful receive the cloud relay package is deleted.
- File content is encrypted with AES-GCM using a per-transfer randomly generated key, which is itself encrypted with the recipient device's public key.

### Stack

The app uses a frontend/backend split architecture:

- **Flutter** renders the UI and handles navigation.
- **Rust** (via `flutter_rust_bridge`) handles all I/O, encryption, and cloud API interactions.
- Both Dart and Rust are cross-platform, enabling Android / iOS / Windows / macOS / Linux from a single codebase.

[![flutter_rust_bridge](https://raw.githubusercontent.com/fzyzcjy/flutter_rust_bridge/master/book/logo.png)](https://github.com/fzyzcjy/flutter_rust_bridge)

## Local Storage

| Platform | Config / Task JSON | Default Download Dir |
|----------|--------------------|----------------------|
| iOS | `Application Support/quarkdrop` | `Documents` |
| Android | `filesDir/quarkdrop` | User-chosen each time |
| Desktop | Platform app-support/config dir | User-chosen (or set in Settings) |

The active paths are shown in **Settings → Open Data Folder** (debug builds).

## License

GPL-3.0-only

