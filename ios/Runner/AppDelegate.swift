import Flutter
import QuickLook
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppInfo") {
      AppDelegate.registerAppInfo(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "Downloads") {
      Downloads.register(messenger: registrar.messenger())
    }
  }

  /// The app's version and ID, and the way to its App Store page, for the
  /// update check and the profile.
  private static func registerAppInfo(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "railway_hrms/app_info", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "info":
        let info = Bundle.main.infoDictionary ?? [:]
        result([
          "version": info["CFBundleShortVersionString"] as? String ?? "",
          "build": info["CFBundleVersion"] as? String ?? "",
          "id": Bundle.main.bundleIdentifier ?? "",
        ])
      case "openStore":
        guard
          let arguments = call.arguments as? [String: Any],
          let link = arguments["url"] as? String,
          let url = URL(string: link)
        else {
          result(false)
          return
        }
        UIApplication.shared.open(url) { opened in result(opened) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// Files the app makes for the user, such as attendance reports: saved in
/// the app's Documents, which the Files app shows under PROMISE, then
/// previewed or shared.
final class Downloads: NSObject, QLPreviewControllerDataSource {
  private static let shared = Downloads()
  private var previewing: URL?

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "railway_hrms/downloads", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let arguments = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "save":
        guard
          let name = arguments["name"] as? String,
          let bytes = arguments["bytes"] as? FlutterStandardTypedData
        else {
          result(FlutterError(code: "failed", message: "Nothing to save", details: nil))
          return
        }
        do {
          result(try shared.save(name: name, data: bytes.data).absoluteString)
        } catch {
          result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
        }
      case "open":
        result(shared.open(arguments["uri"] as? String))
      case "share":
        result(shared.share(arguments["uri"] as? String))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func save(name: String, data: Data) throws -> URL {
    let documents = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    var file = documents.appendingPathComponent(name)
    let stem = file.deletingPathExtension().lastPathComponent
    let ext = file.pathExtension
    var count = 1
    while FileManager.default.fileExists(atPath: file.path) {
      file = documents.appendingPathComponent("\(stem) (\(count)).\(ext)")
      count += 1
    }
    try data.write(to: file, options: .atomic)
    return file
  }

  private static var top: UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }

  private func open(_ link: String?) -> Bool {
    guard let link, let url = URL(string: link), let top = Downloads.top else { return false }
    previewing = url
    let preview = QLPreviewController()
    preview.dataSource = self
    top.present(preview, animated: true)
    return true
  }

  private func share(_ link: String?) -> Bool {
    guard let link, let url = URL(string: link), let top = Downloads.top else { return false }
    let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    sheet.popoverPresentationController?.sourceView = top.view
    sheet.popoverPresentationController?.sourceRect = CGRect(
      x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
    top.present(sheet, animated: true)
    return true
  }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    previewing == nil ? 0 : 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int)
    -> QLPreviewItem
  {
    (previewing ?? URL(fileURLWithPath: "/")) as NSURL
  }
}
