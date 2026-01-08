import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import LinkPresentation

/// Share Extension のメインビューコントローラー
/// カスタムUIを使用してレスポンシブなレイアウトを実現
/// - 共有されたURL/テキストを AppGroup の UserDefaults に保存
/// - ユーザー設定 (RedirectAfterShare) に応じて、保存後にアプリを開くかそのまま終了するかを分岐
class ShareViewController: UIViewController, UITextViewDelegate {
    
    // MARK: - Properties
    
    // AppGroup ID（Runner.entitlements / Share Extension.entitlements と一致させる）
    private let appGroupId = "group.com.MakotoKono.urlManager"
    // 共有データを保存する UserDefaults のキー（receive_sharing_intent と同じキー構造）
    private let sharedDataKey = "ShareKey"
    // リダイレクト設定のキー
    private let redirectSettingKey = "RedirectAfterShare"
    // ホストアプリを開くための URL Scheme
    private let hostAppUrlScheme = "urlmanager://"
    
    // 抽出されたデータ
    private var sharedUrl: String?
    private var sharedTitle: String?
    
    // メタデータプロバイダー
    private var metadataProvider: LPMetadataProvider?
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondarySystemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("キャンセル", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保存", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var titleTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textView.textColor = UIColor.label
        textView.backgroundColor = .clear
        // 編集可能にする
        textView.isEditable = true
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        // スクロールを無効にして固有サイズを使用
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.returnKeyType = .default
        textView.translatesAutoresizingMaskIntoConstraints = false
        // コンテンツに合わせたサイズ調整
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        return textView
    }()
    
    // プレースホルダー用ラベル
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "タイトルを入力"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.placeholderText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var urlLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.secondaryLabel
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.tertiarySystemFill
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // ローディングインジケーター
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var textInfoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // サイズ制約用
    private var containerWidthConstraint: NSLayoutConstraint?
    private var containerHeightConstraint: NSLayoutConstraint?
    private var containerCenterYConstraint: NSLayoutConstraint?
    private var thumbnailWidthConstraint: NSLayoutConstraint?
    private var thumbnailHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractSharedContent()
        
        // テキストビューのデリゲートを設定
        titleTextView.delegate = self
        
        // 背景タップでキーボードを閉じる
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            self?.updateLayoutForSize(size)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayoutForSize(view.bounds.size)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        // コンテナビュー
        view.addSubview(containerView)
        
        // ヘッダービュー
        containerView.addSubview(headerView)
        headerView.addSubview(cancelButton)
        headerView.addSubview(saveButton)
        
        // コンテンツエリア
        containerView.addSubview(contentStackView)
        
        // テキスト情報スタック
        textInfoStackView.addArrangedSubview(titleTextView)
        textInfoStackView.addArrangedSubview(urlLabel)
        
        // プレースホルダーをテキストビューに追加
        titleTextView.addSubview(placeholderLabel)
        
        contentStackView.addArrangedSubview(textInfoStackView)
        contentStackView.addArrangedSubview(thumbnailImageView)
        
        // サムネイルにローディングインジケーターを追加
        thumbnailImageView.addSubview(loadingIndicator)
        
        setupConstraints()
        updateLayoutForSize(view.bounds.size)
    }
    
    private func setupConstraints() {
        // コンテナビューの制約
        containerWidthConstraint = containerView.widthAnchor.constraint(equalToConstant: 340)
        containerHeightConstraint = containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        containerCenterYConstraint = containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerCenterYConstraint!,
            containerWidthConstraint!,
            containerHeightConstraint!,
        ])
        
        // ヘッダービュー
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),
        ])
        
        // キャンセルボタン
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
        ])
        
        // 保存ボタン
        NSLayoutConstraint.activate([
            saveButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            saveButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
        ])
        
        // コンテンツスタック
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
        ])
        
        // サムネイル画像
        thumbnailWidthConstraint = thumbnailImageView.widthAnchor.constraint(equalToConstant: 60)
        thumbnailHeightConstraint = thumbnailImageView.heightAnchor.constraint(equalToConstant: 60)
        
        NSLayoutConstraint.activate([
            thumbnailWidthConstraint!,
            thumbnailHeightConstraint!,
        ])
        
        // ローディングインジケーター（サムネイル中央）
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor),
        ])
        
        // テキストビューの高さ制約（最小高さを設定）
        NSLayoutConstraint.activate([
            titleTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
            titleTextView.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
        ])
        
        // プレースホルダーの位置（textContainerInsetに合わせて調整）
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: titleTextView.topAnchor, constant: 4),
            placeholderLabel.leadingAnchor.constraint(equalTo: titleTextView.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: titleTextView.trailingAnchor),
        ])
    }
    
    private func updateLayoutForSize(_ size: CGSize) {
        let isCompactWidth = size.width < 400
        let isLandscape = size.width > size.height
        
        // コンテナ幅の調整
        let containerWidth: CGFloat
        if isCompactWidth {
            // 小さい画面（iPhone SE など）
            containerWidth = size.width - 32
        } else if isLandscape {
            // 横向き
            containerWidth = min(size.width * 0.6, 400)
        } else {
            // 通常の縦向き
            containerWidth = min(size.width - 48, 360)
        }
        containerWidthConstraint?.constant = containerWidth
        
        // サムネイルサイズの調整
        let thumbnailSize: CGFloat = isCompactWidth ? 50 : 60
        thumbnailWidthConstraint?.constant = thumbnailSize
        thumbnailHeightConstraint?.constant = thumbnailSize
        
        // フォントサイズの調整
        titleTextView.font = UIFont.systemFont(ofSize: isCompactWidth ? 14 : 16, weight: .medium)
        placeholderLabel.font = UIFont.systemFont(ofSize: isCompactWidth ? 14 : 16, weight: .medium)
        urlLabel.font = UIFont.systemFont(ofSize: isCompactWidth ? 11 : 13)
        
        // パディングの調整
        let padding: CGFloat = isCompactWidth ? 12 : 16
        contentStackView.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        
        view.layoutIfNeeded()
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        metadataProvider?.cancel()
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    @objc private func saveTapped() {
        guard let url = sharedUrl else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        metadataProvider?.cancel()
        // テキストビューの内容を保存
        let titleToSave = titleTextView.text?.isEmpty == false ? titleTextView.text : sharedTitle
        saveToAppGroup(url: url, message: titleToSave)
        
        if shouldRedirectToHostApp() {
            openHostApp()
        } else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        // プレースホルダーの表示/非表示を切り替え
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    // MARK: - Content Extraction
    
    private func extractSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            NSLog("[ShareExtension] No extension items found")
            return
        }
        
        NSLog("[ShareExtension] Found \(extensionItems.count) extension items")
        
        for item in extensionItems {
            if let attributedContentText = item.attributedContentText {
                sharedTitle = attributedContentText.string
                titleTextView.text = sharedTitle
                placeholderLabel.isHidden = true
            }
            
            guard let attachments = item.attachments else { continue }
            
            for provider in attachments {
                // URL 型のアイテムを処理
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, error in
                        DispatchQueue.main.async {
                            if let url = item as? URL {
                                self?.sharedUrl = url.absoluteString
                                self?.urlLabel.text = url.host ?? url.absoluteString
                                if self?.sharedTitle == nil || self?.sharedTitle?.isEmpty == true {
                                    self?.titleTextView.text = url.host
                                    self?.placeholderLabel.isHidden = true
                                }
                                // OG画像を取得
                                self?.fetchLinkMetadata(for: url)
                            }
                        }
                    }
                }
                
                // テキスト型のアイテムを処理
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, error in
                        DispatchQueue.main.async {
                            if let text = item as? String {
                                if self?.sharedUrl == nil {
                                    if let extractedUrl = self?.extractUrl(from: text) {
                                        self?.sharedUrl = extractedUrl
                                        self?.urlLabel.text = extractedUrl
                                        // URLからメタデータを取得
                                        if let url = URL(string: extractedUrl) {
                                            self?.fetchLinkMetadata(for: url)
                                        }
                                    }
                                }
                                if self?.sharedTitle == nil || self?.sharedTitle?.isEmpty == true {
                                    self?.sharedTitle = text
                                    self?.titleTextView.text = text
                                    self?.placeholderLabel.isHidden = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Link Metadata
    
    /// LinkPresentationを使用してOG画像を取得
    private func fetchLinkMetadata(for url: URL) {
        // ローディング表示
        loadingIndicator.startAnimating()
        
        metadataProvider = LPMetadataProvider()
        metadataProvider?.startFetchingMetadata(for: url) { [weak self] metadata, error in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                
                if let error = error {
                    NSLog("[ShareExtension] Metadata fetch error: \(error.localizedDescription)")
                    // エラー時はファビコンを試す
                    self?.loadFavicon(for: url)
                    return
                }
                
                guard let metadata = metadata else {
                    self?.loadFavicon(for: url)
                    return
                }
                
                // タイトルが空の場合はメタデータから取得
                if self?.sharedTitle == nil || self?.sharedTitle?.isEmpty == true {
                    self?.sharedTitle = metadata.title
                    self?.titleTextView.text = metadata.title
                    self?.placeholderLabel.isHidden = true
                }
                
                // OG画像を取得
                if let imageProvider = metadata.imageProvider {
                    imageProvider.loadObject(ofClass: UIImage.self) { image, error in
                        DispatchQueue.main.async {
                            if let image = image as? UIImage {
                                self?.thumbnailImageView.image = image
                            } else {
                                // 画像が取得できなかった場合はアイコンを試す
                                self?.loadIconFromMetadata(metadata)
                            }
                        }
                    }
                } else {
                    // 画像プロバイダーがない場合はアイコンを試す
                    self?.loadIconFromMetadata(metadata)
                }
            }
        }
    }
    
    /// メタデータからアイコンを読み込む
    private func loadIconFromMetadata(_ metadata: LPLinkMetadata) {
        if let iconProvider = metadata.iconProvider {
            iconProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    if let image = image as? UIImage {
                        self?.thumbnailImageView.image = image
                    } else if let urlString = self?.sharedUrl, let url = URL(string: urlString) {
                        self?.loadFavicon(for: url)
                    }
                }
            }
        } else if let urlString = sharedUrl, let url = URL(string: urlString) {
            loadFavicon(for: url)
        }
    }
    
    /// ファビコンを読み込む（フォールバック）
    private func loadFavicon(for url: URL) {
        guard let host = url.host,
              let faviconUrl = URL(string: "https://www.google.com/s2/favicons?sz=128&domain=\(host)") else {
            return
        }
        
        URLSession.shared.dataTask(with: faviconUrl) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    self?.thumbnailImageView.image = image
                }
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    
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