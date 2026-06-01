import Foundation

struct PageData {
    let dataId: String
    let source: StackIdentifier
    let target: StackIdentifier
    let route: String?
    let data: [String: Any]
    let timestamp: Int64
    let ttl: Int64

    init(
        dataId: String = UUID().uuidString,
        source: StackIdentifier,
        target: StackIdentifier,
        route: String? = nil,
        data: [String: Any],
        ttl: Int64 = 300_000
    ) {
        self.dataId = dataId
        self.source = source
        self.target = target
        self.route = route
        self.data = data
        self.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        self.ttl = ttl
    }

    var isExpired: Bool {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return now - timestamp > ttl
    }

    func toJSON() -> [String: Any] {
        var json: [String: Any] = [
            "dataId": dataId,
            "source": source.rawValue,
            "target": target.rawValue,
            "data": data,
            "timestamp": timestamp,
            "ttl": ttl
        ]
        if let route = route { json["route"] = route }
        return json
    }

    func toJSONString() -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: toJSON()) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }

    static func from(json: [String: Any]) -> PageData? {
        guard let dataId = json["dataId"] as? String,
              let sourceRaw = json["source"] as? String,
              let source = StackIdentifier(rawValue: sourceRaw),
              let targetRaw = json["target"] as? String,
              let target = StackIdentifier(rawValue: targetRaw),
              let data = json["data"] as? [String: Any] else {
            return nil
        }
        let route = json["route"] as? String
        let ttl = json["ttl"] as? Int64 ?? 300_000
        return PageData(dataId: dataId, source: source, target: target, route: route, data: data, ttl: ttl)
    }

    static func from(jsonString: String) -> PageData? {
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }
        return from(json: json)
    }
}

final class PageDataStore {
    static let shared = PageDataStore()

    private var store: [String: PageData] = [:]
    private var routeDataMap: [String: String] = [:]
    private let queue = DispatchQueue(label: "com.app.pagedatastore", attributes: .concurrent)

    private init() {}

    @discardableResult
    func put(source: StackIdentifier, target: StackIdentifier, route: String? = nil, data: [String: Any], ttl: Int64 = 300_000) -> String {
        let pageData = PageData(source: source, target: target, route: route, data: data, ttl: ttl)
        queue.async(flags: .barrier) {
            self.store[pageData.dataId] = pageData
            if let route = route {
                self.routeDataMap[route] = pageData.dataId
            }
        }
        return pageData.dataId
    }

    func get(dataId: String) -> PageData? {
        var result: PageData?
        queue.sync {
            result = self.store[dataId]
        }
        guard let pageData = result, !pageData.isExpired else {
            remove(dataId: dataId)
            return nil
        }
        return pageData
    }

    func getByRoute(_ route: String) -> PageData? {
        var dataId: String?
        queue.sync {
            dataId = self.routeDataMap[route]
        }
        guard let id = dataId else { return nil }
        return get(dataId: id)
    }

    func consume(dataId: String) -> PageData? {
        let data = get(dataId: dataId)
        if data != nil { remove(dataId: dataId) }
        return data
    }

    func consumeByRoute(_ route: String) -> PageData? {
        var dataId: String?
        queue.sync {
            dataId = self.routeDataMap[route]
        }
        guard let id = dataId else { return nil }
        let data = get(dataId: id)
        if data != nil { remove(dataId: id) }
        return data
    }

    func remove(dataId: String) {
        queue.async(flags: .barrier) {
            if let pageData = self.store.removeValue(forKey: dataId),
               let route = pageData.route {
                self.routeDataMap.removeValue(forKey: route)
            }
        }
    }

    func cleanup() {
        queue.async(flags: .barrier) {
            let expiredIds = self.store.filter { $0.value.isExpired }.map { $0.key }
            expiredIds.forEach { id in
                if let route = self.store[id]?.route {
                    self.routeDataMap.removeValue(forKey: route)
                }
                self.store.removeValue(forKey: id)
            }
        }
    }
}
