import 'package:flutter/material.dart';
import '../bridge/native_router.dart';

class FlutterDetailPage extends StatelessWidget {
  final String? id;

  const FlutterDetailPage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Detail'),
        backgroundColor: const Color(0xFF02569B),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🐦 Flutter',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF02569B),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Detail Page', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('ID: ${id ?? "none"}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => NativeRouter.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02569B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Go Back'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => NativeRouter.toRNHome(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF02569B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Open RN Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
