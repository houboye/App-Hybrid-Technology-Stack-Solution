import Foundation
import WebKit

// MARK: - WebView Message Handler Documentation
/// The WebView bridge works through two mechanisms:
///
/// 1. WebView -> Native: WKScriptMessageHandler
///    - `window.webkit.messageHandlers.eventBus.postMessage(jsonString)` -> dispatched to EventBus
///    - `window.webkit.messageHandlers.router.postMessage(url)` -> dispatched to AppRouter
///
/// 2. Native -> WebView: JavaScript evaluation
///    - `webView.evaluateJavaScript("window.__onNativeEvent('jsonString')")` -> handled by injected JS
///
/// The JS bridge (injected at document start) provides:
///    - `AppRouter.navigate(url)` -- route to any stack
///    - `AppEventBus.sendRequest(target, channel, payload)` -- returns Promise
///    - `AppEventBus.broadcast(channel, payload)` -- send to all
///    - `AppEventBus.subscribe(channel, handler)` -- listen for events
///    - `AppEventBus.respond(originalMsg, payload)` -- reply to a request

/// Helper to create the injected bridge script for external HTML files
struct WebViewBridgeScript {
    static var source: String {
        return WebViewContainerViewController.injectedBridgeJS
    }
}
