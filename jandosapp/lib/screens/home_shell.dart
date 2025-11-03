import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../providers/app_state.dart';
import 'checklist_screen.dart';
import 'history_screen.dart';
import 'user_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final role = AppStateScope.of(context).role;

    // 🔹 Define aba inicial de forma segura
    // (evita erro quando role ainda não está carregado)
    if (role != null) {
      setState(() {
        _index = (role == UserRole.admin) ? 1 : 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final role = app.role;

    // 🔹 Lista de páginas
    final pages = const [
      ChecklistScreen(),
      HistoryScreen(),
      UserScreen(),
    ];

    // 🔹 Labels dinâmicos
    final roleLabel = (role == UserRole.admin)
        ? 'Admin'
        : (role == UserRole.mechanic ? 'Mecânico' : 'Carregando...');

    return Scaffold(
      appBar: AppBar(
        title: Text('Checklist Oficina — $roleLabel'),
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: 'Checklist',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
