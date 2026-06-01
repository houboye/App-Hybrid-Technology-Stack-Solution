import Foundation

final class PageDataBridge {
    static let shared = PageDataBridge()
    private init() {}

    func handleMethodCall(method: String, arguments: String?) -> String? {
        guard let args = arguments else { return nil }

        switch method {
        case "put":
            return handlePut(jsonString: args)
        case "get":
            return handleGet(dataId: args)
        case "consume":
            return handleConsume(dataId: args)
        case "getByRoute":
            return handleGetByRoute(route: args)
        case "consumeByRoute":
            return handleConsumeByRoute(route: args)
        default:
            return nil
        }
    }

    private func handlePut(jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sourceRaw = json["source"] as? String,
              let source = StackIdentifier(rawValue: sourceRaw),
              let targetRaw = json["target"] as? String,
              let target = StackIdentifier(rawValue: targetRaw),
              let payload = json["data"] as? [String: Any] else {
            return nil
        }

        let route = json["route"] as? String
        let ttl = json["ttl"] as? Int64 ?? 300_000

        let dataId = PageDataStore.shared.put(
            source: source,
            target: target,
            route: route,
            data: payload,
            ttl: ttl
        )
        return dataId
    }

    private func handleGet(dataId: String) -> String? {
        return PageDataStore.shared.get(dataId: dataId)?.toJSONString()
    }

    private func handleConsume(dataId: String) -> String? {
        return PageDataStore.shared.consume(dataId: dataId)?.toJSONString()
    }

    private func handleGetByRoute(route: String) -> String? {
        return PageDataStore.shared.getByRoute(route)?.toJSONString()
    }

    private func handleConsumeByRoute(route: String) -> String? {
        return PageDataStore.shared.consumeByRoute(route)?.toJSONString()
    }
}
