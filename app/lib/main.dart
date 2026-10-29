import 'package:flutter/material.dart';

import 'lobby_screen.dart';

void main() => runApp(const FarmCargoApp());

class FarmCargoApp extends StatelessWidget {
  const FarmCargoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '팜카고',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB), // 목업 brand-600
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      ),
      home: const LobbyScreen(), // 1. 앱 실행 시 로비가 먼저 뜬다
    );
  }
}
