import 'dart:convert';
import 'package:flutter/material.dart';
import '../bridge/native_router.dart';
import '../bridge/native_event_bus.dart';
import '../bridge/message_types.dart';
import '../bridge/page_data.dart';

class FlutterHomePage extends StatefulWidget {
  final String? dataId;
  const FlutterHomePage({super.key, this.dataId});

  @override
  State<FlutterHomePage> createState() => _FlutterHomePageState();
}

class _FlutterHomePageState extends State<FlutterHomePage> {
  final List<String> _eventLog = [];
  String _responseText = '';
  String _receivedData = '';
  void Function()? _unsubscribeEvents;
  void Function()? _unsubscribeLifecycle;

  @override
  void initState() {
    super.initState();
    NativeEventBus.init();
    _consumePageData();
    _setupListeners();
  }

  Future<void> _consumePageData() async {
    if (widget.dataId != null && widget.dataId!.isNotEmpty) {
      final entry = await PageData.consume(widget.dataId!);
      if (entry != null) {
        setState(() {
          _receivedData = const JsonEncoder.withIndent('  ').convert(entry.data);
        });
        _appendLog('[PageData] Received from ${entry.source}: ${entry.data}');
      }
    }
  }

  void _setupListeners() {
    _unsubscribeEvents = NativeEventBus.subscribe('*', (msg) {
      if (msg.channel == 'navigationLifecycle') {
        _appendLog('[Lifecycle] ${msg.payload['event']}: ${msg.payload['route']}');
      } else {
        _appendLog('[EventBus] [${msg.source}] ${msg.channel}: ${msg.payload}');
      }
    });

    _unsubscribeLifecycle = NativeRouter.onNavigationEvent('*', (info) {
      _appendLog('[Nav] ${info.event}: ${info.route}');
    });
  }

  @override
  void dispose() {
    _unsubscribeEvents?.call();
    _unsubscribeLifecycle?.call();
    super.dispose();
  }

  void _appendLog(String text) {
    setState(() {
      final time = TimeOfDay.now();
      _eventLog.add('${time.format(context)} $text');
      if (_eventLog.length > 30) _eventLog.removeAt(0);
    });
  }

  // === EventBus ===
  Future<void> _sendRequest() async {
    _appendLog('[EventBus] Sending request to Native: getUserInfo');
    final response = await NativeEventBus.sendRequest(
      'native',
      'getUserInfo',
      {'userId': '1'},
    );
    setState(() {
      _responseText = response.payload.toString();
    });
    _appendLog('[EventBus] Got response: ${response.payload}');
  }

  void _broadcast() {
    NativeEventBus.broadcast('themeChanged', {'theme': 'dark'});
    _appendLog('[EventBus] Broadcast: themeChanged');
  }

  // === PageData ===
  Future<void> _navigateToRNWithData() async {
    final data = {
      'playlist': ['Song A', 'Song B', 'Song C'],
      'currentIndex': 1,
      'source': 'Flutter',
    };
    await NativeRouter.navigateWithData('app://rn/home', data);
    _appendLog('[PageData] Navigate to RN with playlist');
  }

  Future<void> _navigateToWebWithData() async {
    final data = {
      'settings': {'volume': 80, 'quality': 'high'},
      'userId': 'flutter_user_1',
    };
    await NativeRouter.navigateWithData('app://webview?url=local://webHome.html', data);
    _appendLog('[PageData] Navigate to WebView with settings');
  }

  Future<void> _navigateToNativeWithData() async {
    final data = {
      'report': {'type': 'monthly', 'items': 42, 'total': 9999.99},
      'generatedBy': 'Flutter',
    };
    await NativeRouter.navigateWithData('app://native/demo', data);
    _appendLog('[PageData] Navigate to Native with report');
  }

  // === Navigation Control ===
  void _removeRNPage() {
    NativeRouter.removePage('app://rn/home');
    _appendLog('[Router] removePage: app://rn/home');
  }

  void _removeWebViewPage() {
    NativeRouter.removePage('app://webview');
    _appendLog('[Router] removePage: app://webview');
  }

  void _popWithResult() {
    NativeRouter.popWithResult({
      'status': 'completed',
      'result': 'item_selected',
      'from': 'FlutterHome',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Home'),
        backgroundColor: const Color(0xFF02569B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '🐦 Flutter',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF02569B),
              ),
            ),
            const SizedBox(height: 4),
            const Text('All Communication Flows',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 24),

            // Received PageData
            if (_receivedData.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(left: BorderSide(color: Color(0xFF4CAF50), width: 4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Received PageData:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                    const SizedBox(height: 4),
                    Text(_receivedData, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],

            // === EventBus Communication ===
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('EventBus Communication',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            _outlinedButton('Send Request to Native', _sendRequest),
            if (_responseText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('Response: $_responseText',
                    style: const TextStyle(fontSize: 12, color: Colors.green)),
              ),
            _outlinedButton('Broadcast Theme Changed', _broadcast),
            const SizedBox(height: 24),

            // === PageData Transfer ===
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('PageData Transfer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            _navButton('Navigate to RN with Data', _navigateToRNWithData, color: const Color(0xFF61DAFB)),
            _navButton('Navigate to WebView with Data', _navigateToWebWithData, color: const Color(0xFFFF9800)),
            _navButton('Navigate to Native with Data', _navigateToNativeWithData, color: const Color(0xFF4CAF50)),
            const SizedBox(height: 24),

            // === Navigation Control ===
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Navigation Control',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            _navButton('Navigate to React Native', () => NativeRouter.toRNHome()),
            _navButton('Navigate to WebView', () => NativeRouter.toWebView('local://webHome.html')),
            _navButton('Navigate to Native Demo', () => NativeRouter.toNativeDemo()),

            const Divider(height: 20),

            _outlinedButton('Remove RN from Stack', _removeRNPage, color: Colors.red),
            _outlinedButton('Remove WebView from Stack', _removeWebViewPage, color: Colors.red),
            _outlinedButton('Pop with Result Data', _popWithResult, color: Colors.purple),
            const SizedBox(height: 24),

            // Event log
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Event Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 100, maxHeight: 250),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _eventLog.isEmpty
                  ? const Text('No events yet...',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _eventLog
                            .map((e) => Text(e, style: const TextStyle(fontSize: 11)))
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(String text, VoidCallback onPressed, {Color color = const Color(0xFF02569B)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(text),
        ),
      ),
    );
  }

  Widget _outlinedButton(String text, VoidCallback onPressed, {Color color = const Color(0xFF02569B)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(text),
        ),
      ),
    );
  }
}
