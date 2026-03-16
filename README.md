# quarkdrop

QuarkDrop is a Flutter + Rust relay transfer client built on top of Quark.

## Local storage and downloads

- JSON task state is stored under the platform config directory chosen by native code and passed into Rust at startup.
- iOS stores app data under `Application Support/quarkdrop` and receives into `Documents`.
- Android stores app data under `filesDir/quarkdrop` and still asks the user to choose each receive directory.
- Desktop keeps task JSON under the platform application-support/config directory and now asks the user to choose the receive folder each time.

The active paths are shown in the app's **Settings** screen.

## Test support

Test-only Rust support builds fixture trees during unit tests so file, folder, and resume scenarios can be exercised without exposing developer helpers in the app runtime.
