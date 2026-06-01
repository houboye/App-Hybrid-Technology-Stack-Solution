import 'package:flutter/services.dart';

class NativeRouter {
  static const _channel = MethodChannel('com.app.router');

  static Future<void> navigate(String url) async {
    await _channel.invokeMethod('navigate', url);
  }

  static Future<void> pop() async {
    await _channel.invokeMethod('pop');
  }

  static Future<void> toNativeHome() => navigate('app://native/home');
  static Future<void> toNativeDemo() => navigate('app://native/demo');
  static Future<void> toRNHome() => navigate('app://rn/home');
  static Future<void> toRNDetail(String id) => navigate('app://rn/detail?id=$id');
  static Future<void> toFlutterDetail(String id) => navigate('app://flutter/detail?id=$id');
  static Future<void> toWebView(String url) =>
      navigate('app://webview?url=${Uri.encodeComponent(url)}');
}
