import UIKit

class NativeDemoViewController: UIViewController {
    private var eventLog: [String] = []
    private let logTextView = UITextView()
    private let responseLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Native Demo"
        view.backgroundColor = .systemBackground
        setupUI()
        setupEventListeners()
        setupNavigationLifecycleListeners()
    }

    private func setupUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentView = UIStackView()
        contentView.axis = .vertical
        contentView.spacing = 12
        contentView.alignment = .fill
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        // Header
        let header = UILabel()
        header.text = "📱 Native Demo"
        header.font = .systemFont(ofSize: 28, weight: .bold)
        header.textColor = .systemGreen
        header.textAlignment = .center
        contentView.addArrangedSubview(header)

        let subtitle = UILabel()
        subtitle.text = "All Communication Flows"
        subtitle.font = .systemFont(ofSize: 16)
        subtitle.textColor = .secondaryLabel
        subtitle.textAlignment = .center
        contentView.addArrangedSubview(subtitle)

        addSpacer(to: contentView, height: 16)

        // === EventBus Communication ===
        contentView.addArrangedSubview(sectionTitle("EventBus Communication"))

        contentView.addArrangedSubview(makeButton(title: "Send Request to RN", action: #selector(sendRequestToRN)))
        contentView.addArrangedSubview(makeButton(title: "Send Request to Flutter", action: #selector(sendRequestToFlutter)))
        contentView.addArrangedSubview(makeButton(title: "Broadcast to All", action: #selector(broadcastToAll)))
        contentView.addArrangedSubview(makeButton(title: "Notify WebView", action: #selector(notifyWebView)))

        responseLabel.text = ""
        responseLabel.font = .systemFont(ofSize: 12)
        responseLabel.textColor = .systemGreen
        responseLabel.numberOfLines = 0
        contentView.addArrangedSubview(responseLabel)

        addSpacer(to: contentView, height: 16)

        // === PageData Transfer ===
        contentView.addArrangedSubview(sectionTitle("PageData Transfer"))

        contentView.addArrangedSubview(makeButton(title: "Navigate to RN with Data", action: #selector(navigateToRNWithData), style: .filled, color: .systemBlue))
        contentView.addArrangedSubview(makeButton(title: "Navigate to Flutter with Data", action: #selector(navigateToFlutterWithData), style: .filled, color: .systemCyan))
        contentView.addArrangedSubview(makeButton(title: "Navigate to WebView with Data", action: #selector(navigateToWebViewWithData), style: .filled, color: .systemOrange))

        addSpacer(to: contentView, height: 16)

        // === Navigation Control ===
        contentView.addArrangedSubview(sectionTitle("Navigation Control"))

        contentView.addArrangedSubview(makeButton(title: "Open RN Page", action: #selector(openRN), style: .outlined))
        contentView.addArrangedSubview(makeButton(title: "Open Flutter Page", action: #selector(openFlutter), style: .outlined))
        contentView.addArrangedSubview(makeButton(title: "Open WebView Page", action: #selector(openWebView), style: .outlined))

        addSpacer(to: contentView, height: 8)

        contentView.addArrangedSubview(makeButton(title: "Remove RN Page from Stack", action: #selector(removeRNPage), style: .outlined, color: .systemRed))
        contentView.addArrangedSubview(makeButton(title: "Remove Flutter Page from Stack", action: #selector(removeFlutterPage), style: .outlined, color: .systemRed))
        contentView.addArrangedSubview(makeButton(title: "Print Navigation Stack", action: #selector(printNavStack), style: .outlined, color: .systemPurple))

        addSpacer(to: contentView, height: 16)

        // Event log
        contentView.addArrangedSubview(sectionTitle("Event Log"))

        logTextView.isEditable = false
        logTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logTextView.backgroundColor = .secondarySystemBackground
        logTextView.layer.cornerRadius = 8
        logTextView.text = "No events yet..."
        logTextView.textColor = .secondaryLabel
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        logTextView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        contentView.addArrangedSubview(logTextView)
    }

    // MARK: - Event Listeners

    private func setupEventListeners() {
        EventBus.shared.subscribe(channel: "greeting") { [weak self] message in
            self?.appendLog("[EventBus] [\(message.source.rawValue)] greeting: \(message.payload)")
        }
        EventBus.shared.subscribe(channel: "themeChanged") { [weak self] message in
            self?.appendLog("[EventBus] [\(message.source.rawValue)] themeChanged: \(message.payload)")
        }
        EventBus.shared.subscribe(channel: "analytics") { [weak self] message in
            self?.appendLog("[EventBus] [\(message.source.rawValue)] analytics: \(message.payload)")
        }
        EventBus.shared.subscribe(channel: "pageResult") { [weak self] message in
            self?.appendLog("[PageResult] [\(message.source.rawValue)] \(message.payload)")
        }
        EventBus.shared.subscribe(channel: "getUserInfo") { [weak self] message in
            self?.appendLog("[EventBus] [\(message.source.rawValue)] getUserInfo request")
            if message.type == .request, let callbackId = message.callbackId {
                let response = EventMessage(
                    type: .response,
                    channel: message.channel,
                    source: .native,
                    target: message.source,
                    payload: ["name": AnyCodable("Native User"), "id": AnyCodable(42)],
                    callbackId: callbackId
                )
                EventBus.shared.dispatch(message: response)
            }
        }
    }

    private func setupNavigationLifecycleListeners() {
        AppRouter.shared.onNavigationEvent(.pushCompleted) { [weak self] info in
            self?.appendLog("[Lifecycle] pushCompleted: \(info.route)")
        }
        AppRouter.shared.onNavigationEvent(.popCompleted) { [weak self] info in
            self?.appendLog("[Lifecycle] popCompleted: \(info.route)")
        }
        AppRouter.shared.onNavigationEvent(.removeCompleted) { [weak self] info in
            self?.appendLog("[Lifecycle] removeCompleted: \(info.route)")
        }
    }

    // MARK: - EventBus Actions

    @objc private func sendRequestToRN() {
        EventBus.shared.sendRequest(to: .rn, channel: "getUserInfo", payload: ["userId": AnyCodable("1")]) { [weak self] response in
            self?.responseLabel.text = "RN Response: \(response.payload)"
            self?.appendLog("[EventBus] RN response: \(response.payload)")
        }
        appendLog("[EventBus] Sent request to RN: getUserInfo")
    }

    @objc private func sendRequestToFlutter() {
        EventBus.shared.sendRequest(to: .flutter, channel: "getStatus", payload: [:]) { [weak self] response in
            self?.responseLabel.text = "Flutter Response: \(response.payload)"
            self?.appendLog("[EventBus] Flutter response: \(response.payload)")
        }
        appendLog("[EventBus] Sent request to Flutter: getStatus")
    }

    @objc private func broadcastToAll() {
        EventBus.shared.broadcast(channel: "announcement", payload: ["message": AnyCodable("Hello from Native!")])
        appendLog("[EventBus] Broadcast: announcement")
    }

    @objc private func notifyWebView() {
        EventBus.shared.sendNotification(to: .webview, channel: "update", payload: ["action": AnyCodable("refresh")])
        appendLog("[EventBus] Notification to WebView: update")
    }

    // MARK: - PageData Actions

    @objc private func navigateToRNWithData() {
        let data: [String: Any] = [
            "user": ["name": "John", "age": 30, "role": "developer"],
            "items": [1, 2, 3, 4, 5],
            "fromPage": "NativeDemo"
        ]
        AppRouter.shared.navigate(to: Routes.rnHome, data: data, from: self)
        appendLog("[PageData] Navigate to RN with user data")
    }

    @objc private func navigateToFlutterWithData() {
        let data: [String: Any] = [
            "config": ["theme": "dark", "locale": "zh_CN"],
            "message": "Data from Native via PageData",
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        AppRouter.shared.navigate(to: Routes.flutterHome, data: data, from: self)
        appendLog("[PageData] Navigate to Flutter with config data")
    }

    @objc private func navigateToWebViewWithData() {
        let data: [String: Any] = [
            "products": [
                ["id": 1, "name": "iPhone", "price": 999],
                ["id": 2, "name": "iPad", "price": 799]
            ],
            "currency": "USD"
        ]
        AppRouter.shared.navigate(to: Routes.webview(url: "local://webHome.html"), data: data, from: self)
        appendLog("[PageData] Navigate to WebView with products data")
    }

    // MARK: - Navigation Control

    @objc private func openRN() {
        AppRouter.shared.navigate(to: Routes.rnHome, from: self)
    }

    @objc private func openFlutter() {
        AppRouter.shared.navigate(to: Routes.flutterHome, from: self)
    }

    @objc private func openWebView() {
        AppRouter.shared.navigate(to: Routes.webview(url: "local://webHome.html"), from: self)
    }

    @objc private func removeRNPage() {
        AppRouter.shared.removePage(route: Routes.rnHome)
        appendLog("[Router] removePage: app://rn/home")
    }

    @objc private func removeFlutterPage() {
        AppRouter.shared.removePage(route: Routes.flutterHome)
        appendLog("[Router] removePage: app://flutter/home")
    }

    @objc private func printNavStack() {
        let stack = AppRouter.shared.getNavigationStack()
        appendLog("[Router] Stack: \(stack.map { $0["route"] ?? "?" }.joined(separator: " → "))")
    }

    // MARK: - Helpers

    private func appendLog(_ text: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        eventLog.append("\(timestamp) \(text)")
        if eventLog.count > 50 { eventLog.removeFirst() }
        logTextView.text = eventLog.joined(separator: "\n")
        logTextView.textColor = .label
        let bottom = NSRange(location: logTextView.text.count - 1, length: 1)
        logTextView.scrollRangeToVisible(bottom)
    }

    private enum ButtonStyle { case filled, outlined }

    private func makeButton(title: String, action: Selector, style: ButtonStyle = .filled, color: UIColor = .systemGreen) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.layer.cornerRadius = 8

        switch style {
        case .filled:
            button.backgroundColor = color
            button.setTitleColor(.white, for: .normal)
        case .outlined:
            button.backgroundColor = .clear
            button.layer.borderWidth = 1
            button.layer.borderColor = color.cgColor
            button.setTitleColor(color, for: .normal)
        }
        return button
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }

    private func addSpacer(to stack: UIStackView, height: CGFloat) {
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        stack.addArrangedSubview(spacer)
    }
}
