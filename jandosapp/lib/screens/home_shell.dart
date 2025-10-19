import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../providers/app_state.dart';
import 'checklist_screen.dart';
import 'history_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final role = AppStateScope.of(context).role;
    // Garante que admin comece no histórico, mecânico no checklist
    _index = (role == UserRole.admin) ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final role = AppStateScope.of(context).role;
    final pages = [
      const ChecklistScreen(),
      const HistoryScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Checklist Oficina — ${role == UserRole.admin ? 'Admin' : 'Mecânico'}'),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Checklist'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
        ],
      ),
    );
  }
}
