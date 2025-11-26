import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import 'checklist_screen.dart';
import 'history_screen.dart';
import 'user_screen.dart';
import 'orcamento_previo_screen.dart';

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

    // Define aba inicial
    if (role != null) {
      setState(() {
        _index = 0; // Sempre abre no checklist
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppStateScope.of(context);

    // LISTA DE PÁGINAS (agora com orçamento!)
    final pages = const [
      ChecklistScreen(),
      OrcamentoPrevioScreen(checklist: null), // ⬅ NOVA ABA ADICIONADA
      HistoryScreen(),
      UserScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),

      // BARRA DE NAVEGAÇÃO
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            label: 'Checklist',
          ),

          NavigationDestination(
            icon: Icon(Icons.build_rounded),
            label: 'Orçamento',
          ),

          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'Histórico',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
