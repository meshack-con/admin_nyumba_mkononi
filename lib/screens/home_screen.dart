import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'pending_properties_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _authService = AuthService();

  Future<void> _logout() async {
    await _authService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = const [DashboardScreen(), PendingPropertiesScreen()];
    final titles = const ['Dashboard', 'Matangazo Yanayosubiri'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'Toka'),
        ],
      ),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.pending_actions), label: 'Pending'),
        ],
      ),
    );
  }
}
