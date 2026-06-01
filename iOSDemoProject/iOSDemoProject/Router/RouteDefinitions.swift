import Foundation

struct Routes {
    static let nativeHome = "app://native/home"
    static let nativeDemo = "app://native/demo"
    static let rnHome = "app://rn/home"
    static let rnDetail = "app://rn/detail"
    static let flutterHome = "app://flutter/home"
    static let flutterDetail = "app://flutter/detail"
    static let webview = "app://webview"

    static func rnDetail(id: String) -> String {
        return "app://rn/detail?id=\(id)"
    }

    static func flutterDetail(id: String) -> String {
        return "app://flutter/detail?id=\(id)"
    }

    static func webview(url: String) -> String {
        return "app://webview?url=\(url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url)"
    }
}

extension URL {
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }
        var params: [String: String] = [:]
        for item in queryItems {
            params[item.name] = item.value ?? ""
        }
        return params
    }
}
