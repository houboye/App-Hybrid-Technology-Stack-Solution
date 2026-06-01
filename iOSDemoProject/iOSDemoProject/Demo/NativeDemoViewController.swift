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
        subtitle.text = "Communication & Routing Test"
        subtitle.font = .systemFont(ofSize: 16)
        subtitle.textColor = .secondaryLabel
        subtitle.textAlignment = .center
        contentView.addArrangedSubview(subtitle)

        addSpacer(to: contentView, height: 16)

        // Communication section
        let commTitle = sectionTitle("Communication")
        contentView.addArrangedSubview(commTitle)

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

        // Navigation section
        let navTitle = sectionTitle("Navigation")
        contentView.addArrangedSubview(navTitle)

        contentView.addArrangedSubview(makeButton(title: "Open React Native", action: #selector(openRN), style: .outlined))
        contentView.addArrangedSubview(makeButton(title: "Open Flutter", action: #selector(openFlutter), style: .outlined))
        contentView.addArrangedSubview(makeButton(title: "Open WebView", action: #selector(openWebView), style: .outlined))

        addSpacer(to: contentView, height: 16)

        // Event log
        let logTitle = sectionTitle("Event Log")
        contentView.addArrangedSubview(logTitle)

        logTextView.isEditable = false
        logTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logTextView.backgroundColor = .secondarySystemBackground
        logTextView.layer.cornerRadius = 8
        logTextView.text = "No events yet..."
        logTextView.textColor = .secondaryLabel
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        logTextView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        contentView.addArrangedSubview(logTextView)
    }

    private func setupEventListeners() {
        EventBus.shared.subscribe(channel: "greeting") { [weak self] message in
            self?.appendLog("[\(message.source.rawValue)] greeting: \(message.payload)")
        }
        EventBus.shared.subscribe(channel: "themeChanged") { [weak self] message in
            self?.appendLog("[\(message.source.rawValue)] themeChanged: \(message.payload)")
        }
        EventBus.shared.subscribe(channel: "analytics") { [weak self] message in
            self?.appendLog("[\(message.source.rawValue)] analytics: \(message.payload)")
        }
        EventBus.shared.subscribe(channel: "getUserInfo") { [weak self] message in
            self?.appendLog("[\(message.source.rawValue)] getUserInfo request received")
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

    private func appendLog(_ text: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        eventLog.append("\(timestamp) - \(text)")
        if eventLog.count > 50 { eventLog.removeFirst() }
        logTextView.text = eventLog.joined(separator: "\n")
        logTextView.textColor = .label
        let bottom = NSRange(location: logTextView.text.count - 1, length: 1)
        logTextView.scrollRangeToVisible(bottom)
    }

    // MARK: - Communication Actions

    @objc private func sendRequestToRN() {
        EventBus.shared.sendRequest(to: .rn, channel: "getUserInfo", payload: ["userId": AnyCodable("1")]) { [weak self] response in
            self?.responseLabel.text = "RN Response: \(response.payload)"
            self?.appendLog("Got RN response: \(response.payload)")
        }
        appendLog("Sent request to RN: getUserInfo")
    }

    @objc private func sendRequestToFlutter() {
        EventBus.shared.sendRequest(to: .flutter, channel: "getStatus", payload: [:]) { [weak self] response in
            self?.responseLabel.text = "Flutter Response: \(response.payload)"
            self?.appendLog("Got Flutter response: \(response.payload)")
        }
        appendLog("Sent request to Flutter: getStatus")
    }

    @objc private func broadcastToAll() {
        EventBus.shared.broadcast(channel: "announcement", payload: ["message": AnyCodable("Hello from Native!")])
        appendLog("Broadcast sent: announcement")
    }

    @objc private func notifyWebView() {
        EventBus.shared.sendNotification(to: .webview, channel: "update", payload: ["action": AnyCodable("refresh")])
        appendLog("Notification sent to WebView: update")
    }

    // MARK: - Navigation Actions

    @objc private func openRN() {
        AppRouter.shared.navigate(to: Routes.rnHome, from: self)
    }

    @objc private func openFlutter() {
        AppRouter.shared.navigate(to: Routes.flutterHome, from: self)
    }

    @objc private func openWebView() {
        AppRouter.shared.navigate(to: Routes.webview(url: "local://webHome.html"), from: self)
    }

    // MARK: - Helpers

    private enum ButtonStyle { case filled, outlined }

    private func makeButton(title: String, action: Selector, style: ButtonStyle = .filled) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.layer.cornerRadius = 8

        switch style {
        case .filled:
            button.backgroundColor = .systemGreen
            button.setTitleColor(.white, for: .normal)
        case .outlined:
            button.backgroundColor = .clear
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGreen.cgColor
            button.setTitleColor(.systemGreen, for: .normal)
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
