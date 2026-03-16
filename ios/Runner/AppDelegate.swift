import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let platformChannelName = "quarkdrop/platform_paths"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "quarkdrop_platform_paths") {
      let channel = FlutterMethodChannel(
        name: platformChannelName,
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handlePlatformPaths(call: call, result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
      let documentsDir = try requiredDirectory(.documentDirectory, fileManager: fileManager)
      let displayName =
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
      result([
        "configDir": configDir.path,
        "downloadDir": documentsDir.path,
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
