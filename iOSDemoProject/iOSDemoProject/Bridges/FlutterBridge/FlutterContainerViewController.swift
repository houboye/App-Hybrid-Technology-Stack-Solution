import UIKit

class FlutterContainerViewController: UIViewController {
    private let route: String
    private let params: [String: String]
    private let bridgeAdapter = FlutterBridgeAdapter()

    init(route: String, params: [String: String] = [:]) {
        self.route = route
        self.params = params
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Flutter"
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
        badge.text = "🐦 Flutter"
        badge.font = .systemFont(ofSize: 28, weight: .bold)
        badge.textColor = .systemCyan
        stackView.addArrangedSubview(badge)

        let routeLabel = UILabel()
        routeLabel.text = "Route: \(route)"
        routeLabel.font = .systemFont(ofSize: 18)
        routeLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(routeLabel)

        if !params.isEmpty {
            let paramsLabel = UILabel()
            paramsLabel.text = "Params: \(params)"
            paramsLabel.font = .systemFont(ofSize: 14)
            paramsLabel.textColor = .tertiaryLabel
            paramsLabel.numberOfLines = 0
            stackView.addArrangedSubview(paramsLabel)
        }

        let navigateToRN = UIButton(type: .system)
        navigateToRN.setTitle("Navigate to React Native", for: .normal)
        navigateToRN.addTarget(self, action: #selector(goToRN), for: .touchUpInside)
        stackView.addArrangedSubview(navigateToRN)

        let navigateToWebView = UIButton(type: .system)
        navigateToWebView.setTitle("Navigate to WebView", for: .normal)
        navigateToWebView.addTarget(self, action: #selector(goToWebView), for: .touchUpInside)
        stackView.addArrangedSubview(navigateToWebView)

        let navigateToNative = UIButton(type: .system)
        navigateToNative.setTitle("Navigate to Native Demo", for: .normal)
        navigateToNative.addTarget(self, action: #selector(goToNativeDemo), for: .touchUpInside)
        stackView.addArrangedSubview(navigateToNative)

        let sendEventButton = UIButton(type: .system)
        sendEventButton.setTitle("Broadcast from Flutter", for: .normal)
        sendEventButton.addTarget(self, action: #selector(broadcastEvent), for: .touchUpInside)
        stackView.addArrangedSubview(sendEventButton)
    }

    @objc private func goToRN() {
        AppRouter.shared.navigate(to: Routes.rnHome, from: self)
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
            channel: "themeChanged",
            source: .flutter,
            target: .all,
            payload: ["theme": AnyCodable("dark")]
        )
        EventBus.shared.dispatch(message: message)
    }

    deinit {
        EventBus.shared.unregister(stackId: .flutter)
    }
}

// MARK: - Flutter Bridge Adapter
class FlutterBridgeAdapter: EventBridgeAdapter {
    var stackId: StackIdentifier { .flutter }

    func send(message: EventMessage) {
        // Real implementation: methodChannel.invokeMethod("onEventMessage", arguments: message.toJSONString())
        print("[FlutterBridge] Received message on channel '\(message.channel)': \(message.payload)")

        if message.type == .request, let callbackId = message.callbackId {
            let response = EventMessage(
                type: .response,
                channel: message.channel,
                source: .flutter,
                target: message.source,
                payload: ["result": AnyCodable("Response from Flutter"), "originalChannel": AnyCodable(message.channel)],
                callbackId: callbackId
            )
            EventBus.shared.dispatch(message: response)
        }
    }
}
