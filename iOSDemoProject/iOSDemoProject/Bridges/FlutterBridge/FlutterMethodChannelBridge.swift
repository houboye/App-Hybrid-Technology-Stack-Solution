import Foundation

// MARK: - Flutter MethodChannel Bridge (placeholder for actual Flutter integration)
///
/// In a real project, this registers MethodChannel handlers on the FlutterEngine:
///
/// ```swift
/// let eventChannel = FlutterMethodChannel(name: "com.app.eventbus", binaryMessenger: engine.binaryMessenger)
/// eventChannel.setMethodCallHandler { call, result in
///     if call.method == "sendMessage", let json = call.arguments as? String {
///         guard let message = EventMessage.from(jsonString: json) else {
///             result(FlutterError(code: "INVALID", message: "Invalid message JSON", details: nil))
///             return
///         }
///         EventBus.shared.dispatch(message: message)
///         result(nil)
///     }
/// }
///
/// let routerChannel = FlutterMethodChannel(name: "com.app.router", binaryMessenger: engine.binaryMessenger)
/// routerChannel.setMethodCallHandler { call, result in
///     if call.method == "navigate", let url = call.arguments as? String {
///         AppRouter.shared.navigate(to: url)
///         result(nil)
///     } else if call.method == "pop" {
///         AppRouter.shared.pop()
///         result(nil)
///     }
/// }
/// ```
///
/// To send messages TO Flutter:
/// ```swift
/// eventChannel.invokeMethod("onEventMessage", arguments: message.toJSONString())
/// ```
class FlutterMethodChannelBridge {
    static let eventChannelName = "com.app.eventbus"
    static let routerChannelName = "com.app.router"
}
