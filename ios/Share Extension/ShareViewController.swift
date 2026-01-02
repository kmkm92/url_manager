import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

/// Share Extension のメインビューコントローラー
/// receive_sharing_intent と同じ挙動を再現:
/// - 共有されたURL/テキストを AppGroup の UserDefaults に保存
/// - ユーザー設定 (RedirectAfterShare) に応じて、保存後にアプリを開くかそのまま終了するかを分岐
class ShareViewController: SLComposeServiceViewController {
    
    // AppGroup ID（Runner.entitlements / Share Extension.entitlements と一致させる）
    private let appGroupId = "group.com.MakotoKono.urlManager"
    // 共有データを保存する UserDefaults のキー（receive_sharing_intent と同じキー構造）
    private let sharedDataKey = "ShareKey"
    // リダイレクト設定のキー
    private let redirectSettingKey = "RedirectAfterShare"
    // ホストアプリを開くための URL Scheme
    private let hostAppUrlScheme = "urlmanager://"
    
    override func isContentValid() -> Bool {
        // コンテンツが有効かどうかを返す
        return true
    }
    
    override func didSelectPost() {
        // 「投稿」ボタンがタップされた時の処理
        handleSharedItems { [weak self] in
            guard let self = self else { return }
            
            // 設定を確認してリダイレクトするかどうかを決定
            if self.shouldRedirectToHostApp() {
                self.openHostApp()
            } else {
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        }
    }
    
    override func configurationItems() -> [Any]! {
        // 設定項目（今回は不要）
        return []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ナビゲーションバーの設定
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = "保存"
    }
    
    /// AppGroup の設定を読み取り、リダイレクトすべきかどうかを判定
    private func shouldRedirectToHostApp() -> Bool {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else { return false }
        return userDefaults.bool(forKey: redirectSettingKey)
    }
    
    /// ホストアプリを URL Scheme で起動
    private func openHostApp() {
        guard let url = URL(string: hostAppUrlScheme) else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        // Share Extension から直接 openURL を呼ぶには responderChain を使う
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:]) { [weak self] _ in
                    self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                }
                return
            }
            responder = responder?.next
        }
        
        // responderChain で見つからなかった場合は通常終了
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    /// 共有されたアイテムを処理するメインロジック
    private func handleSharedItems(completion: @escaping () -> Void) {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            NSLog("[ShareExtension] No extension items found")
            completion()
            return
        }
        
        NSLog("[ShareExtension] Found \(extensionItems.count) extension items")
        
        // 共有アイテムから URL またはテキストを抽出
        extractSharedContent(from: extensionItems) { [weak self] sharedUrl, sharedText in
            guard let self = self else {
                completion()
                return
            }
            
            NSLog("[ShareExtension] Extracted URL: \(sharedUrl ?? "nil"), Text: \(sharedText ?? "nil")")
            
            // 有効な URL があれば AppGroup に保存
            if let url = sharedUrl ?? self.extractUrl(from: sharedText) {
                let message = self.contentText ?? sharedText
                NSLog("[ShareExtension] Saving URL: \(url)")
                self.saveToAppGroup(url: url, message: message)
            } else {
                NSLog("[ShareExtension] No valid URL found")
            }
            
            completion()
        }
    }
    
    /// NSExtensionItem 配列から URL とテキストを非同期で抽出
    private func extractSharedContent(
        from extensionItems: [NSExtensionItem],
        completion: @escaping (String?, String?) -> Void
    ) {
        var foundUrl: String?
        var foundText: String?
        
        let group = DispatchGroup()
        
        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            
            NSLog("[ShareExtension] Item has \(attachments.count) attachments")
            
            for provider in attachments {
                NSLog("[ShareExtension] Provider types: \(provider.registeredTypeIdentifiers)")
                
                // URL 型のアイテムを処理
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                        if let error = error {
                            NSLog("[ShareExtension] URL load error: \(error)")
                        }
                        if let url = item as? URL {
                            foundUrl = url.absoluteString
                            NSLog("[ShareExtension] Loaded URL: \(url.absoluteString)")
                        }
                        group.leave()
                    }
                }
                
                // テキスト型のアイテムを処理
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, error in
                        if let error = error {
                            NSLog("[ShareExtension] Text load error: \(error)")
                        }
                        if let text = item as? String {
                            // テキスト内に URL が含まれている場合はそれを優先
                            if foundUrl == nil, let extractedUrl = self.extractUrl(from: text) {
                                foundUrl = extractedUrl
                            }
                            foundText = text
                            NSLog("[ShareExtension] Loaded text: \(text)")
                        }
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(foundUrl, foundText)
        }
    }
    
    /// テキストから URL を正規表現で抽出
    private func extractUrl(from text: String?) -> String? {
        guard let text = text else { return nil }
        
        let pattern = "https?://[^\\s]+"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            if let urlRange = Range(match.range, in: text) {
                return String(text[urlRange])
            }
        }
        
        return nil
    }
    
    /// 共有データを AppGroup の UserDefaults に JSON 形式で保存
    /// receive_sharing_intent と同じ形式で保存
    private func saveToAppGroup(url: String, message: String?) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            NSLog("[ShareExtension] Failed to get UserDefaults for AppGroup")
            return
        }
        
        // シンプルな形式で保存（NSNull は使わない）
        let sharedData: [String: Any] = [
            "path": url,
            "message": message ?? "",
            "type": 5  // SharedMediaType.URL = 5
        ]
        
        // 既存の共有データ配列を取得
        var existingData = userDefaults.array(forKey: sharedDataKey) as? [[String: Any]] ?? []
        existingData.append(sharedData)
        
        userDefaults.set(existingData, forKey: sharedDataKey)
        userDefaults.synchronize()
        
        NSLog("[ShareExtension] Saved data to AppGroup. Total items: \(existingData.count)")
        
        // 保存確認
        let savedData = userDefaults.array(forKey: sharedDataKey)
        NSLog("[ShareExtension] Verification - saved data count: \(savedData?.count ?? 0)")
    }
}