import 'dart:convert';
import 'package:flutter/services.dart';
import 'page_data.dart';
import 'native_event_bus.dart';
import 'message_types.dart';

class NavigationLifecycleInfo {
  final String event;
  final String route;
  final int timestamp;

  NavigationLifecycleInfo({
    required this.event,
    required this.route,
    required this.timestamp,
  });

  factory NavigationLifecycleInfo.fromPayload(Map<String, dynamic> payload) {
    return NavigationLifecycleInfo(
      event: payload['event'] as String? ?? '',
      route: payload['route'] as String? ?? '',
      timestamp: payload['timestamp'] as int? ?? 0,
    );
  }
}

typedef NavigationLifecycleHandler = void Function(NavigationLifecycleInfo info);

class NativeRouter {
  static const _channel = MethodChannel('com.app.router');
  static final List<_HandlerEntry> _lifecycleHandlers = [];
  static bool _listenerInitialized = false;

  static void _ensureListener() {
    if (_listenerInitialized) return;
    _listenerInitialized = true;
    NativeEventBus.init();
    NativeEventBus.subscribe('navigationLifecycle', (EventMessage msg) {
      final info = NavigationLifecycleInfo.fromPayload(msg.payload);
      for (final entry in _lifecycleHandlers) {
        if (entry.event == info.event || entry.event == '*') {
          entry.handler(info);
        }
      }
    });
  }

  static Future<void> navigate(String url) async {
    await _channel.invokeMethod('navigate', url);
  }

  static Future<String> navigateWithData(
    String url,
    Map<String, dynamic> data, {
    int ttl = 300000,
  }) async {
    final host = url.replaceFirst('app://', '').split('/')[0];
    final dataId = await PageData.put(host, data, route: url, ttl: ttl);
    final separator = url.contains('?') ? '&' : '?';
    await _channel.invokeMethod('navigate', '$url${separator}_dataId=$dataId');
    return dataId;
  }

  static Future<void> pop() async {
    await _channel.invokeMethod('pop');
  }

  static Future<void> popWithResult(Map<String, dynamic> data) async {
    await _channel.invokeMethod('popWithResult', jsonEncode(data));
  }

  static Future<void> removePage(String route) async {
    await _channel.invokeMethod('removePage', route);
  }

  static Future<List<Map<String, String>>> getNavigationStack() async {
    final result = await _channel.invokeMethod<List>('getNavigationStack');
    return result?.cast<Map<String, String>>() ?? [];
  }

  static void Function() onNavigationEvent(
    String event,
    NavigationLifecycleHandler handler,
  ) {
    _ensureListener();
    final entry = _HandlerEntry(event: event, handler: handler);
    _lifecycleHandlers.add(entry);
    return () => _lifecycleHandlers.remove(entry);
  }

  static Future<void> toNativeHome() => navigate('app://native/home');
  static Future<void> toNativeDemo() => navigate('app://native/demo');
  static Future<void> toRNHome() => navigate('app://rn/home');
  static Future<void> toRNDetail(String id) => navigate('app://rn/detail?id=$id');
  static Future<void> toFlutterDetail(String id) => navigate('app://flutter/detail?id=$id');
  static Future<void> toWebView(String url) =>
      navigate('app://webview?url=${Uri.encodeComponent(url)}');
}

class _HandlerEntry {
  final String event;
  final NavigationLifecycleHandler handler;
  _HandlerEntry({required this.event, required this.handler});
}
