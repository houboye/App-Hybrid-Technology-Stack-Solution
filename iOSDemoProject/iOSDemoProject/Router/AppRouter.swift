import UIKit

final class AppRouter {
    static let shared = AppRouter()

    private weak var navigationController: UINavigationController?

    private init() {}

    func setup(with navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func navigate(to urlString: String, from viewController: UIViewController? = nil) {
        guard let url = URL(string: urlString), let host = url.host else { return }

        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let params = url.queryParameters

        let targetVC: UIViewController

        switch host {
        case "native":
            targetVC = resolveNative(path: path, params: params)
        case "rn":
            targetVC = RNContainerViewController(moduleName: path.isEmpty ? "home" : path, initialProperties: params)
        case "flutter":
            targetVC = FlutterContainerViewController(route: path.isEmpty ? "/" : "/\(path)", params: params)
        case "webview":
            let webURL = params["url"] ?? ""
            targetVC = WebViewContainerViewController(urlString: webURL)
        default:
            return
        }

        let nav = navigationController
            ?? (viewController as? UINavigationController)
            ?? viewController?.navigationController

        DispatchQueue.main.async {
            nav?.pushViewController(targetVC, animated: true)
        }
    }

    func pop() {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }

    private func resolveNative(path: String, params: [String: String]) -> UIViewController {
        switch path {
        case "demo":
            return NativeDemoViewController()
        case "home":
            return ViewController()
        default:
            return ViewController()
        }
    }
}
