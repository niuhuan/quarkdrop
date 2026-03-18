import Flutter
import Photos
import PhotosUI
import UniformTypeIdentifiers
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let platformChannelName = "quarkdrop/platform_paths"
  private let backgroundChannelName = "quarkdrop/background"
  private let photoPickerChannelName = "quarkdrop/photo_picker"
  private var preservingPhotoPicker: PreservingPhotoPicker?

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
    if let registrar = self.registrar(forPlugin: "quarkdrop_background") {
      let bgChannel = FlutterMethodChannel(
        name: backgroundChannelName,
        binaryMessenger: registrar.messenger()
      )
      bgChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "getKeepScreenOn":
          result(UIApplication.shared.isIdleTimerDisabled)
        case "setKeepScreenOn":
          if let value = call.arguments as? Bool {
            DispatchQueue.main.async {
              UIApplication.shared.isIdleTimerDisabled = value
            }
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    if let registrar = self.registrar(forPlugin: "quarkdrop_photo_picker") {
      let photoChannel = FlutterMethodChannel(
        name: photoPickerChannelName,
        binaryMessenger: registrar.messenger()
      )
      photoChannel.setMethodCallHandler { [weak self] call, result in
        self?.handlePhotoPicker(call: call, result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handlePhotoPicker(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "pickImagesPreservingNames" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard #available(iOS 14, *) else {
      result(
        FlutterError(
          code: "photo_picker_unsupported",
          message: "This picker requires iOS 14 or later.",
          details: nil
        ))
      return
    }
    guard preservingPhotoPicker == nil else {
      result(
        FlutterError(
          code: "photo_picker_busy",
          message: "A photo picker request is already in progress.",
          details: nil
        ))
      return
    }
    guard let controller = rootFlutterViewController() else {
      result(
        FlutterError(
          code: "photo_picker_unavailable",
          message: "Unable to locate the current Flutter view controller.",
          details: nil
        ))
      return
    }

    let picker = PreservingPhotoPicker()
    preservingPhotoPicker = picker
    picker.pick(from: controller) { [weak self] pickedItems, error in
      self?.preservingPhotoPicker = nil
      if let error {
        result(
          FlutterError(
            code: error.code,
            message: error.message,
            details: error.details
          ))
      } else {
        result(
          pickedItems.map { item in
            [
              "path": item.path,
              "name": item.name,
            ]
          })
      }
    }
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

  private func rootFlutterViewController() -> UIViewController? {
    if let controller = window?.rootViewController {
      return controller
    }
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController
  }
}

private struct PickedPhotoItem {
  let index: Int
  let path: String
  let name: String
}

private struct PickedPhotoError {
  let code: String
  let message: String
  let details: Any?
}

@available(iOS 14, *)
private final class PreservingPhotoPicker: NSObject, PHPickerViewControllerDelegate {
  private var completion: (([PickedPhotoItem], PickedPhotoError?) -> Void)?

  func pick(
    from presentingViewController: UIViewController,
    completion: @escaping ([PickedPhotoItem], PickedPhotoError?) -> Void
  ) {
    var configuration = PHPickerConfiguration(photoLibrary: .shared())
    configuration.filter = .images
    configuration.selectionLimit = 0
    configuration.preferredAssetRepresentationMode = .current

    let picker = PHPickerViewController(configuration: configuration)
    picker.delegate = self
    self.completion = completion
    DispatchQueue.main.async {
      presentingViewController.present(picker, animated: true)
    }
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard let completion else {
      return
    }
    guard !results.isEmpty else {
      self.completion = nil
      completion([], nil)
      return
    }

    let dispatchGroup = DispatchGroup()
    let lock = NSLock()
    var pickedItems = [PickedPhotoItem]()
    var firstError: PickedPhotoError?

    for (index, result) in results.enumerated() {
      dispatchGroup.enter()
      loadPhoto(result: result, index: index) { item, error in
        lock.lock()
        if let item {
          pickedItems.append(item)
        } else if firstError == nil, let error {
          firstError = error
        }
        lock.unlock()
        dispatchGroup.leave()
      }
    }

    dispatchGroup.notify(queue: .main) {
      self.completion = nil
      if let firstError {
        completion([], firstError)
      } else {
        completion(pickedItems.sorted(by: { $0.index < $1.index }), nil)
      }
    }
  }

  private func loadPhoto(
    result: PHPickerResult,
    index: Int,
    completion: @escaping (PickedPhotoItem?, PickedPhotoError?) -> Void
  ) {
    let provider = result.itemProvider
    let typeIdentifier = UTType.image.identifier
    guard provider.hasItemConformingToTypeIdentifier(typeIdentifier) else {
      completion(
        nil,
        PickedPhotoError(
          code: "photo_picker_invalid_item",
          message: "One of the selected items is not an image.",
          details: nil
        ))
      return
    }

    provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
      if let error {
        completion(
          nil,
          PickedPhotoError(
            code: "photo_picker_load_failed",
            message: error.localizedDescription,
            details: nil
          ))
        return
      }
      guard let url else {
        completion(
          nil,
          PickedPhotoError(
            code: "photo_picker_missing_url",
            message: "The selected image could not be loaded.",
            details: nil
          ))
        return
      }

      do {
        let originalName = self.originalFilename(for: result, fallbackURL: url)
        let copiedPath = try self.copyImageToTemporaryDirectory(from: url, originalName: originalName)
        completion(PickedPhotoItem(index: index, path: copiedPath, name: originalName), nil)
      } catch {
        completion(
          nil,
          PickedPhotoError(
            code: "photo_picker_copy_failed",
            message: error.localizedDescription,
            details: nil
          ))
      }
    }
  }

  private func originalFilename(for result: PHPickerResult, fallbackURL: URL) -> String {
    if let assetIdentifier = result.assetIdentifier {
      let fetchResult = PHAsset.fetchAssets(
        withLocalIdentifiers: [assetIdentifier],
        options: nil
      )
      if let asset = fetchResult.firstObject {
        let resources = PHAssetResource.assetResources(for: asset)
        if let name = resources.first(where: { $0.type == .photo || $0.type == .fullSizePhoto })?
          .originalFilename,
          !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
          return name
        }
        if let name = resources.first?.originalFilename,
          !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
          return name
        }
      }
    }
    return fallbackURL.lastPathComponent
  }

  private func copyImageToTemporaryDirectory(from sourceURL: URL, originalName: String) throws -> String {
    let fileManager = FileManager.default
    let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(
      "quarkdrop_picked_images",
      isDirectory: true
    )
    try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

    let sanitizedName = originalName.trimmingCharacters(in: .whitespacesAndNewlines)
    let baseName = ((sanitizedName as NSString).deletingPathExtension.isEmpty
      ? "image"
      : (sanitizedName as NSString).deletingPathExtension)
    let fileExtension = (sanitizedName as NSString).pathExtension.isEmpty
      ? sourceURL.pathExtension
      : (sanitizedName as NSString).pathExtension
    let uniqueName = fileExtension.isEmpty
      ? "\(baseName)_\(UUID().uuidString)"
      : "\(baseName)_\(UUID().uuidString).\(fileExtension)"
    let destinationURL = tempDirectory.appendingPathComponent(uniqueName, isDirectory: false)

    if fileManager.fileExists(atPath: destinationURL.path) {
      try fileManager.removeItem(at: destinationURL)
    }
    try fileManager.copyItem(at: sourceURL, to: destinationURL)
    return destinationURL.path
  }
}
