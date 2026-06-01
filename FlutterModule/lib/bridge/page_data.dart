import 'dart:convert';
import 'package:flutter/services.dart';

class PageDataEntry {
  final String dataId;
  final String source;
  final String target;
  final String? route;
  final Map<String, dynamic> data;
  final int timestamp;
  final int ttl;

  PageDataEntry({
    required this.dataId,
    required this.source,
    required this.target,
    this.route,
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  factory PageDataEntry.fromJson(Map<String, dynamic> json) {
    return PageDataEntry(
      dataId: json['dataId'] as String,
      source: json['source'] as String,
      target: json['target'] as String,
      route: json['route'] as String?,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      timestamp: json['timestamp'] as int,
      ttl: json['ttl'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataId': dataId,
      'source': source,
      'target': target,
      'route': route,
      'data': data,
      'timestamp': timestamp,
      'ttl': ttl,
    };
  }
}

class PageData {
  static const _channel = MethodChannel('com.app.pagedata');

  static Future<String> put(
    String target,
    Map<String, dynamic> data, {
    String? route,
    int ttl = 300000,
  }) async {
    final payload = jsonEncode({
      'source': 'flutter',
      'target': target,
      'route': route,
      'data': data,
      'ttl': ttl,
    });
    final dataId = await _channel.invokeMethod<String>('put', payload);
    return dataId!;
  }

  static Future<PageDataEntry?> get(String dataId) async {
    final jsonString = await _channel.invokeMethod<String>('get', dataId);
    if (jsonString == null) return null;
    return PageDataEntry.fromJson(jsonDecode(jsonString));
  }

  static Future<PageDataEntry?> consume(String dataId) async {
    final jsonString = await _channel.invokeMethod<String>('consume', dataId);
    if (jsonString == null) return null;
    return PageDataEntry.fromJson(jsonDecode(jsonString));
  }

  static Future<PageDataEntry?> getByRoute(String route) async {
    final jsonString = await _channel.invokeMethod<String>('getByRoute', route);
    if (jsonString == null) return null;
    return PageDataEntry.fromJson(jsonDecode(jsonString));
  }

  static Future<PageDataEntry?> consumeByRoute(String route) async {
    final jsonString =
        await _channel.invokeMethod<String>('consumeByRoute', route);
    if (jsonString == null) return null;
    return PageDataEntry.fromJson(jsonDecode(jsonString));
  }
}
