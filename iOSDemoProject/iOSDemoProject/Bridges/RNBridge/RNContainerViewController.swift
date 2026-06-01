import UIKit

class RNContainerViewController: UIViewController {
    private let moduleName: String
    private let initialProperties: [String: String]
    private let bridgeAdapter = RNBridgeAdapter()

    init(moduleName: String, initialProperties: [String: String] = [:]) {
        self.moduleName = moduleName
        self.initialProperties = initialProperties
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "React Native"
        view.backgroundColor = .systemBackground
        setupUI()
        EventBus.shared.register(adapter: bridgeAdapter)
    }

    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20)
        ])

        let badge = UILabel()
        badge.text = "⚛️ React Native"
        badge.font = .systemFont(ofSize: 28, weight: .bold)
        badge.textColor = .systemBlue
        stackView.addArrangedSubview(badge)

        let moduleLabel = UILabel()
        moduleLabel.text = "Module: \(moduleName)"
        moduleLabel.font = .systemFont(ofSize: 18)
        moduleLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(moduleLabel)

        if !initialProperties.isEmpty {
            let paramsLabel = UILabel()
            paramsLabel.text = "Params: \(initialProperties)"
            paramsLabel.font = .systemFont(ofSize: 14)
            paramsLabel.textColor = .tertiaryLabel
            paramsLabel.numberOfLines = 0
            stackView.addArrangedSubview(paramsLabel)
        }

        let navigateToFlutter = UIButton(type: .system)
        navigateToFlutter.setTitle("Navigate to Flutter", for: .normal)
        navigateToFlutter.addTarget(self, action: #selector(goToFlutter), for: .touchUpInside)
        stackView.addArrangedSubview(navigateToFlutter)

        let navigateToWebView = UIButton(type: .system)
        navigateToWebView.setTitle("Navigate to WebView", for: .normal)
        navigateToWebView.addTarget(self, action: #selector(goToWebView), for: .touchUpInside)
        stackView.addArrangedSubview(navigateToWebView)

        let navigateToNative = UIButton(type: .system)
        navigateToNative.setTitle("Navigate to Native Demo", for: .normal)
        navigateToNative.addTarget(self, action: #selector(goToNativeDemo), for: .touchUpInside)
        stackView.addArrangedSubview(navigateToNative)

        let sendEventButton = UIButton(type: .system)
        sendEventButton.setTitle("Broadcast from RN", for: .normal)
        sendEventButton.addTarget(self, action: #selector(broadcastEvent), for: .touchUpInside)
        stackView.addArrangedSubview(sendEventButton)
    }

    @objc private func goToFlutter() {
        AppRouter.shared.navigate(to: Routes.flutterHome, from: self)
    }

    @objc private func goToWebView() {
        AppRouter.shared.navigate(to: Routes.webview(url: "local://webHome.html"), from: self)
    }

    @objc private func goToNativeDemo() {
        AppRouter.shared.navigate(to: Routes.nativeDemo, from: self)
    }

    @objc private func broadcastEvent() {
        let message = EventMessage(
            type: .broadcast,
            channel: "greeting",
            source: .rn,
            target: .all,
            payload: ["message": AnyCodable("Hello from React Native!")]
        )
        EventBus.shared.dispatch(message: message)
    }

    deinit {
        EventBus.shared.unregister(stackId: .rn)
    }
}

// MARK: - RN Bridge Adapter
class RNBridgeAdapter: EventBridgeAdapter {
    var stackId: StackIdentifier { .rn }

    func send(message: EventMessage) {
        // In a real implementation, this would emit an event via RCTEventEmitter
        // For demo: print to console
        print("[RNBridge] Received message on channel '\(message.channel)': \(message.payload)")

        // Auto-respond to requests for demo purposes
        if message.type == .request, let callbackId = message.callbackId {
            let response = EventMessage(
                type: .response,
                channel: message.channel,
                source: .rn,
                target: message.source,
                payload: ["result": AnyCodable("Response from RN"), "originalChannel": AnyCodable(message.channel)],
                callbackId: callbackId
            )
            EventBus.shared.dispatch(message: response)
        }
    }
}
