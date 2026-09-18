import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nyumba Mkononi Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const _StartupGate(),
    );
  }
}

/// Inaangalia kama tayari kuna token iliyohifadhiwa ili kuamua kuanzia
/// na LoginScreen au moja kwa moja HomeScreen.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _loading = true;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await AuthService().getToken();
    if (!mounted) return;
    setState(() {
      _hasToken = token != null && token.isNotEmpty;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _hasToken ? const HomeScreen() : const LoginScreen();
  }
}
