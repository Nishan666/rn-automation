import Expo
import React
import ReactAppDependencyProvider

@UIApplicationMain
public class AppDelegate: ExpoAppDelegate {
var window: UIWindow?

var reactNativeDelegate: ExpoReactNativeFactoryDelegate?
var reactNativeFactory: RCTReactNativeFactory?

public override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
) -> Bool {
  let delegate = ReactNativeDelegate()
  let factory = ExpoReactNativeFactory(delegate: delegate)
  delegate.dependencyProvider = RCTAppDependencyProvider()

  reactNativeDelegate = delegate
  reactNativeFactory = factory
  bindReactNativeFactory(factory)

#if os(iOS) || os(tvOS)
  window = UIWindow(frame: UIScreen.main.bounds)
  factory.startReactNative(
    withModuleName: "main",
    in: window,
    launchOptions: launchOptions)
#endif

  return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}

// Linking API
public override func application(
  _ app: UIApplication,
  open url: URL,
  options: [UIApplication.OpenURLOptionsKey: Any] = [:]
) -> Bool {
  return super.application(app, open: url, options: options) || RCTLinkingManager.application(app, open: url, options: options)
}

// Universal Links
public override func application(
  _ application: UIApplication,
  continue userActivity: NSUserActivity,
  restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
) -> Bool {
  let result = RCTLinkingManager.application(application, continue: userActivity, restorationHandler: restorationHandler)
  return super.application(application, continue: userActivity, restorationHandler: restorationHandler) || result
}
}

class ReactNativeDelegate: ExpoReactNativeFactoryDelegate {
// Extension point for config-plugins

override func sourceURL(for bridge: RCTBridge) -> URL? {
  // needed to return the correct URL for expo-dev-client.
  bridge.bundleURL ?? bundleURL()
}

override func bundleURL() -> URL? {
#if DEBUG
  let urlProvider = RCTBundleURLProvider.sharedSettings()
   // Try with ".expo/.virtual-metro-entry" for Expo dev-client (preferred)
  if let url = urlProvider.jsBundleURL(forBundleRoot: ".expo/.virtual-metro-entry") {
    return url
  }
   // Try with "index" as bundle root (matches package.json "main": "index.js")
  if let url = urlProvider.jsBundleURL(forBundleRoot: "index") {
    return url
  }
   // Fallback: Extract port from RCTBundleURLProvider by trying different bundle roots
  // This automatically detects both host and port without hardcoding
  let host = urlProvider.jsLocation ?? "localhost"
  var port: String? = nil
   // Try multiple bundle roots to find one that works and extract the port
  let bundleRootsToTry = ["index", "main", ""]
  for bundleRoot in bundleRootsToTry {
    if let testUrl = urlProvider.jsBundleURL(forBundleRoot: bundleRoot) {
      if let detectedPort = testUrl.port {
        port = String(detectedPort)
        break
      }
    }
  }
   // If we couldn't detect port from jsBundleURL, use RCTBundleURLProvider's default port
  // Metro bundler defaults to port 8081, which RCTBundleURLProvider also uses by default
  // This is a safe fallback when jsBundleURL returns nil for all bundle roots
  let finalPort = port ?? "8081"
   // Construct Expo dev-client URL using detected host and port
  let bundleRoot = ".expo/.virtual-metro-entry"
  let urlString = "http://\(host):\(finalPort)/\(bundleRoot).bundle?platform=ios&dev=true"
  return URL(string: urlString)
#else
  return Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
}
}
