import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../providers/app_state.dart';
import '../widgets/checklist_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    if (app.role != UserRole.admin) {
      return const Center(child: Text('Acesso restrito ao Admin.'));
    }
    final items = app.checklists;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: items.isEmpty
            ? const Center(child: Text('Sem checklists ainda.'))
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => ChecklistCard(item: items[i]),
              ),
      ),
    );
  }
}