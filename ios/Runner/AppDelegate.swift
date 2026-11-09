import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  private var saveResult: FlutterResult?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "hermes_mobile/files",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "save" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self = self, self.saveResult == nil,
            let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(FlutterError(code: "save_failed", message: "Salvamento indisponível.", details: nil))
        return
      }
      let source = URL(fileURLWithPath: path).resolvingSymlinksInPath()
      let privateRoot = URL(fileURLWithPath: NSTemporaryDirectory()).resolvingSymlinksInPath()
      guard source.path.hasPrefix(privateRoot.path + "/"),
            source.deletingLastPathComponent().lastPathComponent.hasPrefix("hermes-download-"),
            FileManager.default.fileExists(atPath: source.path),
            var presenter = UIApplication.shared.connectedScenes
              .compactMap({ $0 as? UIWindowScene })
              .flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.rootViewController else {
        result(FlutterError(code: "save_failed", message: "Não foi possível salvar o arquivo.", details: nil))
        return
      }
      while let presented = presenter.presentedViewController { presenter = presented }
      self.saveResult = result
      let picker = UIDocumentPickerViewController(forExporting: [source], asCopy: true)
      picker.delegate = self
      picker.modalPresentationStyle = .fullScreen
      presenter.present(picker, animated: !UIAccessibility.isReduceMotionEnabled)
    }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    let result = saveResult
    saveResult = nil
    result?(!urls.isEmpty)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = saveResult
    saveResult = nil
    result?(false)
  }
}
