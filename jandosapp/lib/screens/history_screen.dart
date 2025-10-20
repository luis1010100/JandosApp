import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/user_role.dart';
import '../models/checklist.dart';
import '../screens/checklist_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  bool _isHttp(String path) => path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);

    final checklists = (app.role == UserRole.admin)
        ? app.checklists
        : app.checklists.where((c) => c.createdBy == app.userName).toList();

    if (checklists.isEmpty) {
      return const Center(child: Text('Nenhum checklist encontrado.'));
    }

    final df = DateFormat('dd/MM/yyyy HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: checklists.length,
      itemBuilder: (context, index) {
        final c = checklists[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text('${c.nomeCliente} — ${c.placa}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Carro: ${c.nomeCarro} (${c.modeloCarro})'),
                Text('Marca/Cor: ${c.marcaCarro} / ${c.corCarro}'),
                Text('Ano: ${c.anoCarro}'),
                Text('Observações: ${c.observacoes.isEmpty ? "—" : c.observacoes}'),
                Text('Criado por: ${c.createdBy} (${c.createdByRole.name})'),
                Text('Data: ${df.format(c.createdAt)}'),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Ver detalhes',
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _mostrarDetalhes(context, c),
                ),
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChecklistScreen(editing: c)),
                    );
                    // AppStateScope notifica e a lista reconstrói sozinha
                  },
                ),
                IconButton(
                  tooltip: 'Excluir',
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
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDetalhes(BuildContext context, Checklist item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalhes do Checklist'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Placa: ${item.placa}'),
              Text('Cliente: ${item.nomeCliente}'),
              Text('Carro: ${item.nomeCarro}'),
              Text('Modelo: ${item.modeloCarro}'),
              Text('Marca: ${item.marcaCarro}'),
              Text('Ano: ${item.anoCarro}'),
              Text('Cor: ${item.corCarro}'),
              const SizedBox(height: 12),
              const Text('Observações:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(item.observacoes.isEmpty ? '—' : item.observacoes),
              const SizedBox(height: 12),
              const Text('Fotos:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (item.fotos.isEmpty)
                const Text('Nenhuma foto.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.fotos.map((p) {
                    return _isHttp(p.path)
                        ? Image.network(p.path, width: 100, height: 100, fit: BoxFit.cover)
                        : Image.file(File(p.path), width: 100, height: 100, fit: BoxFit.cover);
                  }).toList(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }
}