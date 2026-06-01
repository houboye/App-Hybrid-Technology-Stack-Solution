import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'message_types.dart';

class NativeEventBus {
  static const _channel = MethodChannel('com.app.eventbus');
  static final _uuid = Uuid();
  static final _pendingCallbacks = <String, Completer<EventMessage>>{};
  static final _channelHandlers = <String, List<void Function(EventMessage)>>{};
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onEventMessage') {
        final msg = EventMessage.fromJson(jsonDecode(call.arguments as String));

        if (msg.type == 'response' && msg.callbackId != null) {
          _pendingCallbacks.remove(msg.callbackId)?.complete(msg);
          return;
        }

        _channelHandlers[msg.channel]?.forEach((h) => h(msg));
        _channelHandlers['*']?.forEach((h) => h(msg));
      }
    });
  }

  static Future<EventMessage> sendRequest(
    String target,
    String channel, [
    Map<String, dynamic> payload = const {},
  ]) {
    final callbackId = _uuid.v4();
    final msg = EventMessage(
      id: _uuid.v4(),
      type: 'request',
      channel: channel,
      source: 'flutter',
      target: target,
      payload: payload,
      callbackId: callbackId,
    );
    final completer = Completer<EventMessage>();
    _pendingCallbacks[callbackId] = completer;
    _channel.invokeMethod('sendMessage', jsonEncode(msg.toJson()));
    return completer.future;
  }

  static void sendNotification(
    String target,
    String channel, [
    Map<String, dynamic> payload = const {},
  ]) {
    final msg = EventMessage(
      id: _uuid.v4(),
      type: 'notification',
      channel: channel,
      source: 'flutter',
      target: target,
      payload: payload,
    );
    _channel.invokeMethod('sendMessage', jsonEncode(msg.toJson()));
  }

  static void broadcast(String channel, [Map<String, dynamic> payload = const {}]) {
    final msg = EventMessage(
      id: _uuid.v4(),
      type: 'broadcast',
      channel: channel,
      source: 'flutter',
      target: '*',
      payload: payload,
    );
    _channel.invokeMethod('sendMessage', jsonEncode(msg.toJson()));
  }

  static void respond(EventMessage originalMsg, [Map<String, dynamic> payload = const {}]) {
    final msg = EventMessage(
      id: _uuid.v4(),
      type: 'response',
      channel: originalMsg.channel,
      source: 'flutter',
      target: originalMsg.source,
      payload: payload,
      callbackId: originalMsg.callbackId,
    );
    _channel.invokeMethod('sendMessage', jsonEncode(msg.toJson()));
  }

  static void Function() subscribe(String channel, void Function(EventMessage) handler) {
    _channelHandlers.putIfAbsent(channel, () => []);
    _channelHandlers[channel]!.add(handler);
    return () {
      _channelHandlers[channel]?.remove(handler);
    };
  }
}
