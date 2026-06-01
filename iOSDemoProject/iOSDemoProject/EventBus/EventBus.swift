import Foundation

final class EventBus {
    static let shared = EventBus()

    private var adapters: [StackIdentifier: EventBridgeAdapter] = [:]
    private var channelListeners: [String: [(EventMessage) -> Void]] = [:]
    private var pendingCallbacks: [String: (EventMessage) -> Void] = [:]
    private let queue = DispatchQueue(label: "com.app.eventbus", attributes: .concurrent)

    private init() {}

    func register(adapter: EventBridgeAdapter) {
        queue.async(flags: .barrier) {
            self.adapters[adapter.stackId] = adapter
        }
    }

    func unregister(stackId: StackIdentifier) {
        queue.async(flags: .barrier) {
            self.adapters.removeValue(forKey: stackId)
        }
    }

    func dispatch(message: EventMessage) {
        queue.async {
            if message.type == .response, let cbId = message.callbackId {
                if let callback = self.pendingCallbacks[cbId] {
                    self.queue.async(flags: .barrier) {
                        self.pendingCallbacks.removeValue(forKey: cbId)
                    }
                    DispatchQueue.main.async { callback(message) }
                }
                return
            }

            if message.type == .broadcast || message.target == .all {
                for (stackId, adapter) in self.adapters where stackId != message.source {
                    DispatchQueue.main.async { adapter.send(message: message) }
                }
                self.notifyListeners(channel: message.channel, message: message)
                return
            }

            if message.target == .native {
                self.notifyListeners(channel: message.channel, message: message)
            } else if let adapter = self.adapters[message.target] {
                DispatchQueue.main.async { adapter.send(message: message) }
            }
        }
    }

    func sendRequest(
        to target: StackIdentifier,
        channel: String,
        payload: [String: AnyCodable] = [:],
        completion: @escaping (EventMessage) -> Void
    ) {
        let callbackId = UUID().uuidString
        let message = EventMessage(
            type: .request,
            channel: channel,
            source: .native,
            target: target,
            payload: payload,
            callbackId: callbackId
        )
        queue.async(flags: .barrier) {
            self.pendingCallbacks[callbackId] = completion
        }
        dispatch(message: message)
    }

    func sendNotification(to target: StackIdentifier, channel: String, payload: [String: AnyCodable] = [:]) {
        let message = EventMessage(
            type: .notification,
            channel: channel,
            source: .native,
            target: target,
            payload: payload
        )
        dispatch(message: message)
    }

    func broadcast(channel: String, payload: [String: AnyCodable] = [:]) {
        let message = EventMessage(
            type: .broadcast,
            channel: channel,
            source: .native,
            target: .all,
            payload: payload
        )
        dispatch(message: message)
    }

    func subscribe(channel: String, handler: @escaping (EventMessage) -> Void) {
        queue.async(flags: .barrier) {
            self.channelListeners[channel, default: []].append(handler)
        }
    }

    private func notifyListeners(channel: String, message: EventMessage) {
        let listeners = self.channelListeners[channel] ?? []
        DispatchQueue.main.async {
            listeners.forEach { $0(message) }
        }
    }
}
