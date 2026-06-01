import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hybrid App Demo"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "🏠 Hybrid App Hub"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        stackView.addArrangedSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.text = "Navigate between tech stacks"
        descLabel.font = .systemFont(ofSize: 16)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        stackView.addArrangedSubview(descLabel)

        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
        stackView.addArrangedSubview(spacer)

        stackView.addArrangedSubview(makeButton(title: "⚛️  React Native", color: .systemBlue, action: #selector(openRN)))
        stackView.addArrangedSubview(makeButton(title: "🐦  Flutter", color: .systemCyan, action: #selector(openFlutter)))
        stackView.addArrangedSubview(makeButton(title: "🌐  WebView", color: .systemOrange, action: #selector(openWebView)))
        stackView.addArrangedSubview(makeButton(title: "📱  Native Demo", color: .systemGreen, action: #selector(openNativeDemo)))
    }

    private func makeButton(title: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func openRN() {
        AppRouter.shared.navigate(to: Routes.rnHome, from: self)
    }

    @objc private func openFlutter() {
        AppRouter.shared.navigate(to: Routes.flutterHome, from: self)
    }

    @objc private func openWebView() {
        AppRouter.shared.navigate(to: Routes.webview(url: "local://webHome.html"), from: self)
    }

    @objc private func openNativeDemo() {
        AppRouter.shared.navigate(to: Routes.nativeDemo, from: self)
    }
}

