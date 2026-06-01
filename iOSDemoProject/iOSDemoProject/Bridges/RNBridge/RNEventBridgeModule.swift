import Foundation

// MARK: - RCTBridgeModule Interface (placeholder for actual React Native integration)
// In a real project, this class would:
// 1. Extend RCTEventEmitter
// 2. Be annotated with @objc(EventBridgeModule) and RCT_EXPORT_MODULE()
// 3. Expose these methods to JavaScript via RCT_EXPORT_METHOD:

/// Interface documentation for the React Native native module
///
/// JavaScript usage:
/// ```js
/// import { NativeModules, NativeEventEmitter } from 'react-native';
/// const { EventBridgeModule } = NativeModules;
/// const emitter = new NativeEventEmitter(EventBridgeModule);
///
/// // Send a message to native EventBus
/// EventBridgeModule.sendMessage(JSON.stringify(message));
///
/// // Listen for messages from native
/// emitter.addListener('onEventMessage', (jsonString) => { ... });
/// ```
class RNEventBridgeModule {

    /// Called from RN JS: sends a message into the native EventBus
    func sendMessage(_ jsonString: String) {
        guard let message = EventMessage.from(jsonString: jsonString) else { return }
        EventBus.shared.dispatch(message: message)
    }

    /// Called from native: forwards a message to RN JS runtime via RCTEventEmitter
    func emitToJS(message: EventMessage) {
        // In real implementation: self.sendEvent(withName: "onEventMessage", body: message.toJSONString())
        print("[RNEventBridgeModule] Would emit to JS: \(message.channel)")
    }
}
