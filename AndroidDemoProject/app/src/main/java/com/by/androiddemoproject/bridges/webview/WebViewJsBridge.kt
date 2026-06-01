package com.by.androiddemoproject.bridges.webview

// MARK: - WebView Bridge Documentation
// The WebView bridge uses two mechanisms:
//
// 1. WebView → Native: @JavascriptInterface methods
//    - AndroidBridge.navigate(url) → AppRouter.navigate(context, url)
//    - AndroidBridge.sendMessage(json) → EventBus.dispatch(message)
//
// 2. Native → WebView: evaluateJavascript
//    - webView.evaluateJavascript("window.__onNativeEvent('$json')", null)
//
// The bridge script is injected via onPageFinished. It provides:
//    - AppRouter.navigate(url) — wraps AndroidBridge.navigate
//    - AppEventBus.sendRequest(target, channel, payload) — returns Promise
//    - AppEventBus.broadcast(channel, payload) — send to all
//    - AppEventBus.subscribe(channel, handler) — listen for events
//    - AppEventBus.respond(originalMsg, payload) — reply to request

object WebViewJsBridgeDoc {
    const val ROUTER_INTERFACE = "AndroidBridge"
}
