import Flutter
import UIKit

@objc(DevelopifyViewController)
final class DevelopifyViewController: FlutterViewController {
  private var hasRenderedFirstFrame = false

  override var preferredStatusBarStyle: UIStatusBarStyle {
    hasRenderedFirstFrame ? super.preferredStatusBarStyle : .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setFlutterViewDidRenderCallback { [weak self] in
      self?.hasRenderedFirstFrame = true
      self?.setNeedsStatusBarAppearanceUpdate()
    }
  }
}

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
  }
}
