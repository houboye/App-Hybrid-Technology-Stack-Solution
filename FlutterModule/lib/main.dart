import 'package:flutter/material.dart';
import 'pages/flutter_home_page.dart';
import 'pages/flutter_detail_page.dart';
import 'bridge/native_event_bus.dart';

void main() => runApp(const FlutterModuleApp());

class FlutterModuleApp extends StatelessWidget {
  const FlutterModuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    NativeEventBus.init();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Module',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF02569B),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        final path = uri.path;
        final params = uri.queryParameters;

        switch (path) {
          case '/':
          case '/home':
            return MaterialPageRoute(builder: (_) => const FlutterHomePage());
          case '/detail':
            return MaterialPageRoute(
              builder: (_) => FlutterDetailPage(id: params['id']),
            );
          default:
            return MaterialPageRoute(builder: (_) => const FlutterHomePage());
        }
      },
    );
  }
}
