import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    // 共有データを管理するための定数
    private let appGroupId = "group.com.MakotoKono.urlManager"
    private let sharedDataKey = "ShareKey"
    private let redirectSettingKey = "RedirectAfterShare"
    private let channelName = "com.MakotoKono.urlManager/share"
    
    private var shareChannel: FlutterMethodChannel?
    private var shareEventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Flutter エンジンへの MethodChannel と EventChannel を設定
        setupChannels()
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    /// MethodChannel と EventChannel を設定し Flutter 側からの呼び出しを処理
    private func setupChannels() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            NSLog("[AppDelegate] Failed to get FlutterViewController")
            return
        }
        
        NSLog("[AppDelegate] Setting up channels")
        
        // MethodChannel: getInitialMedia, reset, setRedirectAfterShare 用
        shareChannel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: controller.binaryMessenger
        )
        
        shareChannel?.setMethodCallHandler { [weak self] (call, result) in
            NSLog("[AppDelegate] MethodChannel call: \(call.method)")
            
            switch call.method {
            case "getInitialMedia":
                // 初回起動時の共有データを取得
                let items = self?.getSharedItems() ?? []
                NSLog("[AppDelegate] getInitialMedia returning \(items.count) items")
                result(items)
                
            case "reset":
                // 共有データをクリア
                NSLog("[AppDelegate] Clearing shared items")
                self?.clearSharedItems()
                result(nil)
                
            case "setRedirectAfterShare":
                // 共有後のリダイレクト設定を AppGroup に保存
                if let enabled = call.arguments as? Bool {
                    self?.setRedirectAfterShare(enabled)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Boolean argument expected", details: nil))
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // EventChannel: getMediaStream 用（アプリ起動中のストリーム）
        shareEventChannel = FlutterEventChannel(
            name: "\(channelName)/stream",
            binaryMessenger: controller.binaryMessenger
        )
        shareEventChannel?.setStreamHandler(self)
    }
    
    /// AppGroup の UserDefaults から共有データを取得
    private func getSharedItems() -> [[String: Any]] {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            NSLog("[AppDelegate] Failed to get UserDefaults for AppGroup")
            return []
        }
        
        let items = userDefaults.array(forKey: sharedDataKey) as? [[String: Any]] ?? []
        NSLog("[AppDelegate] getSharedItems found \(items.count) items")
        
        // デバッグ：アイテムの内容を表示
        for (index, item) in items.enumerated() {
            NSLog("[AppDelegate] Item \(index): \(item)")
        }
        
        return items
    }
    
    /// AppGroup の共有データをクリア
    private func clearSharedItems() {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            return
        }
        
        userDefaults.removeObject(forKey: sharedDataKey)
        userDefaults.synchronize()
    }
    
    /// リダイレクト設定を AppGroup に保存
    private func setRedirectAfterShare(_ enabled: Bool) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            return
        }
        userDefaults.set(enabled, forKey: redirectSettingKey)
        userDefaults.synchronize()
    }
    
    /// アプリがフォアグラウンドに復帰した時に共有データをチェック
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        
        NSLog("[AppDelegate] applicationDidBecomeActive")
        
        // 新しい共有データがあればストリームに流す
        let items = getSharedItems()
        if !items.isEmpty {
            NSLog("[AppDelegate] Sending \(items.count) items to stream")
            eventSink?(items)
        }
    }
    
    /// URL Scheme からアプリが起動された場合の処理
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        NSLog("[AppDelegate] Opened with URL: \(url)")
        
        // 共有データがあればストリームに流す
        let items = getSharedItems()
        if !items.isEmpty {
            NSLog("[AppDelegate] Sending \(items.count) items to stream from URL open")
            eventSink?(items)
        }
        return super.application(app, open: url, options: options)
    }
}

// MARK: - FlutterStreamHandler
extension AppDelegate: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        NSLog("[AppDelegate] EventChannel onListen")
        self.eventSink = events
        
        // リスナー登録時に既存データがあれば送信
        let items = getSharedItems()
        if !items.isEmpty {
            NSLog("[AppDelegate] Sending existing \(items.count) items on listen")
            events(items)
        }
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NSLog("[AppDelegate] EventChannel onCancel")
        self.eventSink = nil
        return nil
    }
}
