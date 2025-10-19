import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../models/user_role.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late AppState app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    app = AppStateScope.of(context);
  }

  @override
  Widget build(BuildContext context) {
    // Filtra checklists: admins veem todos, mecânicos só os próprios
    final checklists = (app.role == UserRole.admin)
        ? app.checklists
        : app.checklists.where((c) => c.createdBy == app.userName).toList();

    if (checklists.isEmpty) {
      return const Center(
        child: Text('Nenhum checklist encontrado.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: checklists.length,
      itemBuilder: (context, index) {
        final c = checklists[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('${c.nomeCliente} — ${c.placa}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Carro: ${c.nomeCarro} (${c.modeloCarro})'),
                Text('Marca/Cor: ${c.marcaCarro} / ${c.corCarro}'),
                Text('Ano: ${c.anoCarro}'),
                Text('Observações: ${c.observacoes}'),
                Text('Criado por: ${c.createdBy} (${c.createdByRole.name})'),
                Text('Data: ${c.createdAt.toLocal()}'),
              ],
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Confirmar exclusão'),
                    content: const Text('Deseja realmente excluir este checklist?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
                    ],
                  ),
                );
                if (confirm == true) {
                  app.removeChecklist(c);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
