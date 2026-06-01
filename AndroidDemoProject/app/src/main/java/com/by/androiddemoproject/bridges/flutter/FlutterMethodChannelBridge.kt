package com.by.androiddemoproject.bridges.flutter

// MARK: - MethodChannel Bridge documentation
// In a real project, register these in FlutterContainerActivity.configureFlutterEngine():
//
// val eventChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.app.eventbus")
// eventChannel.setMethodCallHandler { call, result ->
//     when (call.method) {
//         "sendMessage" -> {
//             val json = call.arguments as? String ?: return@setMethodCallHandler
//             val message = EventMessage.fromJSONString(json) ?: run {
//                 result.error("INVALID", "Invalid message JSON", null)
//                 return@setMethodCallHandler
//             }
//             EventBus.dispatch(message)
//             result.success(null)
//         }
//     }
// }
//
// val routerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.app.router")
// routerChannel.setMethodCallHandler { call, result ->
//     when (call.method) {
//         "navigate" -> {
//             val url = call.arguments as? String ?: return@setMethodCallHandler
//             AppRouter.navigate(context, url)
//             result.success(null)
//         }
//         "pop" -> {
//             finish()
//             result.success(null)
//         }
//     }
// }
//
// To send TO Flutter:
// eventChannel.invokeMethod("onEventMessage", message.toJSONString())
//
// PageData MethodChannel:
// val pageDataChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.app.pagedata")
// pageDataChannel.setMethodCallHandler { call, result ->
//     val response = PageDataBridge.handleMethodCall(call.method, call.arguments as? String)
//     result.success(response)
// }

object FlutterMethodChannelBridge {
    const val EVENT_CHANNEL_NAME = "com.app.eventbus"
    const val ROUTER_CHANNEL_NAME = "com.app.router"
    const val PAGE_DATA_CHANNEL_NAME = "com.app.pagedata"
}
