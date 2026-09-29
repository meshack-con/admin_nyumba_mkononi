import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'add_property_screen.dart';
import 'all_properties_screen.dart';
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
  int _refreshKey = 0; // inabadilika baada ya kuongeza nyumba ili orodha zipakuliwe upya
  final _authService = AuthService();

  Future<void> _logout() async {
    await _authService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _addProperty() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
    );
    if (added == true && mounted) {
      setState(() => _refreshKey++);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nyumba imewekwa na sasa inaonekana kwa watumiaji')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(key: ValueKey('dash$_refreshKey')),
      PendingPropertiesScreen(key: ValueKey('pend$_refreshKey')),
      AllPropertiesScreen(key: ValueKey('all$_refreshKey')),
    ];
    final titles = const ['Dashboard', 'Matangazo Yanayosubiri', 'Nyumba Zote'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(onPressed: _addProperty, icon: const Icon(Icons.add_home_work), tooltip: 'Ongeza Nyumba'),
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
          NavigationDestination(icon: Icon(Icons.home_work), label: 'Nyumba Zote'),
        ],
      ),
    );
  }
}
