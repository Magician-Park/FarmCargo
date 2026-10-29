import 'package:flutter/material.dart';

import 'lobby_screen.dart';
import 'login_screen.dart';
import 'shipper_lobby_screen.dart';

void main() => runApp(const FarmCargoApp());

class FarmCargoApp extends StatefulWidget {
  const FarmCargoApp({super.key});

  @override
  State<FarmCargoApp> createState() => _FarmCargoAppState();
}

class _FarmCargoAppState extends State<FarmCargoApp> {
  // 데모 로그인 상태는 메모리에만 유지한다. 앱 재실행 시 다시 로그인한다.
  AccountRole? _role;

  void _logout() => setState(() => _role = null);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '팜카고',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      home: switch (_role) {
        AccountRole.driver => LobbyScreen(onLogout: _logout),
        AccountRole.shipper => ShipperLobbyScreen(onLogout: _logout),
        null => LoginScreen(onLogin: (role) => setState(() => _role = role)),
      },
    );
  }
}
