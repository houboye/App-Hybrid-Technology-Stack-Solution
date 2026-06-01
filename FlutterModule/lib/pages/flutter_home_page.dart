import 'package:flutter/material.dart';
import '../bridge/native_router.dart';
import '../bridge/native_event_bus.dart';
import '../bridge/message_types.dart';

class FlutterHomePage extends StatefulWidget {
  const FlutterHomePage({super.key});

  @override
  State<FlutterHomePage> createState() => _FlutterHomePageState();
}

class _FlutterHomePageState extends State<FlutterHomePage> {
  final List<String> _eventLog = [];
  String _responseText = '';
  void Function()? _unsubscribe;

  @override
  void initState() {
    super.initState();
    NativeEventBus.init();
    _unsubscribe = NativeEventBus.subscribe('*', (msg) {
      setState(() {
        _eventLog.add('[${msg.source}] ${msg.channel}: ${msg.payload}');
        if (_eventLog.length > 20) _eventLog.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final response = await NativeEventBus.sendRequest(
      'native',
      'getUserInfo',
      {'userId': '1'},
    );
    setState(() {
      _responseText = response.payload.toString();
    });
  }

  void _broadcast() {
    NativeEventBus.broadcast('themeChanged', {'theme': 'dark'});
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
            const Text('Home Page', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 24),

            // Navigation section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Navigation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            _navButton('Navigate to React Native', () => NativeRouter.toRNHome()),
            _navButton('Navigate to WebView', () => NativeRouter.toWebView('local://webHome.html')),
            _navButton('Navigate to Native Demo', () => NativeRouter.toNativeDemo()),
            _navButton('Navigate to Flutter Detail (id=456)', () => NativeRouter.toFlutterDetail('456')),
            const SizedBox(height: 24),

            // Communication section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Communication', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

            // Event log
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Event Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 100, maxHeight: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _eventLog.isEmpty
                  ? const Text('No events yet...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _eventLog
                          .map((e) => Text(e, style: const TextStyle(fontSize: 11)))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF02569B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(text),
        ),
      ),
    );
  }

  Widget _outlinedButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF02569B),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(text),
        ),
      ),
    );
  }
}
