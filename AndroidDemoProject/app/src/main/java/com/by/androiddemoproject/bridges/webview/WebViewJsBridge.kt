package com.by.androiddemoproject.bridges.webview

import com.by.androiddemoproject.pagedata.PageDataBridge

// MARK: - WebView Bridge Documentation
// The WebView bridge uses two mechanisms:
//
// 1. WebView → Native: @JavascriptInterface methods
//    - AndroidBridge.navigate(url) → AppRouter.navigate(context, url)
//    - AndroidBridge.sendMessage(json) → EventBus.dispatch(message)
//    - AndroidBridge.pageDataPut(requestId, payload) → PageDataBridge.handleMethodCall("put", ...)
//    - AndroidBridge.pageDataGet(requestId, dataId) → PageDataBridge.handleMethodCall("get", ...)
//    - AndroidBridge.pageDataConsume(requestId, dataId) → PageDataBridge.handleMethodCall("consume", ...)
//
// 2. Native → WebView: evaluateJavascript
//    - webView.evaluateJavascript("window.__onNativeEvent('$json')", null)
//    - webView.evaluateJavascript("window.__onPageDataResponse('$requestId', '$result')", null)
//
// The bridge script is injected via onPageFinished. It provides:
//    - AppRouter.navigate(url) — wraps AndroidBridge.navigate
//    - AppEventBus.sendRequest(target, channel, payload) — returns Promise
//    - AppEventBus.broadcast(channel, payload) — send to all
//    - AppEventBus.subscribe(channel, handler) — listen for events
//    - AppEventBus.respond(originalMsg, payload) — reply to request
//    - PageData.put(target, data, route, ttl) — store data for page transfer
//    - PageData.get(dataId) / PageData.consume(dataId) — retrieve data
//    - PageData.getFromURL() — auto-extract dataId from URL and consume
//    - PageData.navigateWithData(url, data, ttl) — navigate with attached data

object WebViewJsBridgeDoc {
    const val ROUTER_INTERFACE = "AndroidBridge"
}
