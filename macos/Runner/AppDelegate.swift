import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private let platformChannelName = "quarkdrop/platform_paths"

  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: platformChannelName,
        binaryMessenger: controller.engine.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handlePlatformPaths(call: call, result: result)
      }
    }
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func handlePlatformPaths(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "getPlatformPaths" else {
      result(FlutterMethodNotImplemented)
      return
    }

    do {
      let fileManager = FileManager.default
      let appSupportBase = try requiredDirectory(.applicationSupportDirectory, fileManager: fileManager)
      let configDir = appSupportBase.appendingPathComponent("quarkdrop", isDirectory: true)
      try fileManager.createDirectory(at: configDir, withIntermediateDirectories: true)
      let downloadsDir = try requiredDirectory(.downloadsDirectory, fileManager: fileManager)
      let displayName =
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
      result([
        "configDir": configDir.path,
        "downloadDir": downloadsDir.path,
        "displayName": (displayName?.isEmpty == false ? displayName! : "QuarkDrop"),
        "requiresDownloadPicker": false,
      ])
    } catch {
      result(
        FlutterError(
          code: "platform_paths_error",
          message: error.localizedDescription,
          details: nil
        ))
    }
  }

  private func requiredDirectory(
    _ directory: FileManager.SearchPathDirectory,
    fileManager: FileManager
  ) throws -> URL {
    guard let url = fileManager.urls(for: directory, in: .userDomainMask).first else {
      throw NSError(
        domain: "QuarkDropPaths",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Unable to resolve \(directory) directory."]
      )
    }
    return url
  }
}
