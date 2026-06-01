import UIKit

// MARK: - Navigation Lifecycle Events

enum NavigationEvent: String {
    case pushCompleted
    case popCompleted
    case removeCompleted
}

struct NavigationLifecycleInfo {
    let event: NavigationEvent
    let route: String
    let timestamp: Int64

    func toDictionary() -> [String: Any] {
        return [
            "event": event.rawValue,
            "route": route,
            "timestamp": timestamp
        ]
    }
}

typealias NavigationLifecycleHandler = (NavigationLifecycleInfo) -> Void

// MARK: - AppRouter

final class AppRouter: NSObject {
    static let shared = AppRouter()

    private weak var navigationController: UINavigationController?
    private var routeMap: [UIViewController: String] = [:]
    private var lifecycleHandlers: [String: [NavigationLifecycleHandler]] = [:]
    private var pendingPushRoute: String?
    private var pendingPopRoutes: [String] = []

    private override init() { super.init() }

    func setup(with navigationController: UINavigationController) {
        self.navigationController = navigationController
        navigationController.delegate = self
    }

    // MARK: - Navigation

    func navigate(to urlString: String, from viewController: UIViewController? = nil) {
        navigate(to: urlString, data: nil, from: viewController)
    }

    func navigate(to urlString: String, data: [String: Any]?, from viewController: UIViewController? = nil) {
        guard let url = URL(string: urlString), let host = url.host else { return }

        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var params = url.queryParameters

        if let data = data {
            let target: StackIdentifier = StackIdentifier(rawValue: host) ?? .native
            let dataId = PageDataStore.shared.put(
                source: .native,
                target: target,
                route: urlString,
                data: data
            )
            params["_dataId"] = dataId
        }

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

        routeMap[targetVC] = urlString
        pendingPushRoute = urlString

        let nav = navigationController
            ?? (viewController as? UINavigationController)
            ?? viewController?.navigationController

        DispatchQueue.main.async {
            nav?.pushViewController(targetVC, animated: true)
        }
    }

    func pop() {
        guard let nav = navigationController,
              let topVC = nav.topViewController,
              let route = routeMap[topVC] else {
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
            return
        }
        pendingPopRoutes = [route]
        DispatchQueue.main.async {
            nav.popViewController(animated: true)
        }
    }

    func pop(withResult data: [String: Any]?) {
        if let data = data {
            EventBus.shared.broadcast(channel: "pageResult", payload: data.mapValues { AnyCodable($0) })
        }
        pop()
    }

    // MARK: - Remove Page by Route

    func removePage(route: String) {
        guard let nav = navigationController else { return }
        var viewControllers = nav.viewControllers
        var removedRoutes: [String] = []

        viewControllers.removeAll { vc in
            if let vcRoute = routeMap[vc], matchRoute(vcRoute, pattern: route) {
                routeMap.removeValue(forKey: vc)
                removedRoutes.append(vcRoute)
                return true
            }
            return false
        }

        guard !removedRoutes.isEmpty else { return }
        pendingPopRoutes = removedRoutes

        DispatchQueue.main.async {
            nav.setViewControllers(viewControllers, animated: true)
        }
    }

    func getNavigationStack() -> [[String: String]] {
        guard let nav = navigationController else { return [] }
        return nav.viewControllers.compactMap { vc in
            guard let route = routeMap[vc] else { return nil }
            return ["route": route, "index": "\(nav.viewControllers.firstIndex(of: vc) ?? 0)"]
        }
    }

    // MARK: - Lifecycle Listeners

    @discardableResult
    func onNavigationEvent(_ event: NavigationEvent, handler: @escaping NavigationLifecycleHandler) -> String {
        let id = UUID().uuidString
        let key = "\(event.rawValue)_\(id)"
        lifecycleHandlers[event.rawValue, default: []].append(handler)
        return key
    }

    func removeNavigationListener(id: String) {
        let parts = id.split(separator: "_", maxSplits: 1)
        guard let eventKey = parts.first else { return }
        lifecycleHandlers[String(eventKey)] = nil
    }

    // MARK: - Private

    private func notifyLifecycle(event: NavigationEvent, route: String) {
        let info = NavigationLifecycleInfo(
            event: event,
            route: route,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000)
        )
        lifecycleHandlers[event.rawValue]?.forEach { $0(info) }

        EventBus.shared.broadcast(
            channel: "navigationLifecycle",
            payload: info.toDictionary().mapValues { AnyCodable($0) }
        )
    }

    private func matchRoute(_ route: String, pattern: String) -> Bool {
        if route == pattern { return true }
        guard let routeURL = URL(string: route),
              let patternURL = URL(string: pattern) else { return false }
        return routeURL.host == patternURL.host
            && routeURL.path == patternURL.path
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

// MARK: - UINavigationControllerDelegate

extension AppRouter: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        if let pushRoute = pendingPushRoute {
            pendingPushRoute = nil
            notifyLifecycle(event: .pushCompleted, route: pushRoute)
        }

        if !pendingPopRoutes.isEmpty {
            let routes = pendingPopRoutes
            pendingPopRoutes = []
            for route in routes {
                notifyLifecycle(event: .popCompleted, route: route)
            }
        }

        let currentVCs = Set(navigationController.viewControllers)
        let staleEntries = routeMap.filter { !currentVCs.contains($0.key) }
        staleEntries.forEach { routeMap.removeValue(forKey: $0.key) }
    }
}
