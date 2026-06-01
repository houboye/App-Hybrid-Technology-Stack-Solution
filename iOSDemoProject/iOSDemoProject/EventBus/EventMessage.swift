import Foundation

enum MessageType: String, Codable {
    case request
    case response
    case notification
    case broadcast
}

enum StackIdentifier: String, Codable {
    case native
    case rn
    case flutter
    case webview
    case all = "*"
}

struct EventMessage: Codable {
    let id: String
    let type: MessageType
    let channel: String
    let source: StackIdentifier
    let target: StackIdentifier
    let payload: [String: AnyCodable]
    let callbackId: String?
    let timestamp: Int64

    init(
        id: String = UUID().uuidString,
        type: MessageType,
        channel: String,
        source: StackIdentifier,
        target: StackIdentifier,
        payload: [String: AnyCodable] = [:],
        callbackId: String? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.type = type
        self.channel = channel
        self.source = source
        self.target = target
        self.payload = payload
        self.callbackId = callbackId
        self.timestamp = timestamp
    }

    func toJSONString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func from(jsonString: String) -> EventMessage? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(EventMessage.self, from: data)
    }

    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }
}

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
