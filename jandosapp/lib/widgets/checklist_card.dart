import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/checklist.dart';

class ChecklistCard extends StatelessWidget {
  final Checklist item;
  const ChecklistCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.receipt_long),
        title: Text('${item.nomeCarro} • ${item.modeloCarro} • ${item.corCarro}'),
        subtitle: Text(
            'Cliente: ${item.nomeCliente}\nPlaca: ${item.placa}\nCriado: ${df.format(item.createdAt)} por ${item.createdBy}'),
        isThreeLine: true,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(onPressed: () => _mostrarDetalhes(context, item), icon: const Icon(Icons.visibility)),
          IconButton(
            onPressed: () => _editarChecklist(context, item),
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
        ]),
      ),
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
              Text('Observações: ${item.observacoes}'),
              const SizedBox(height: 12),
              const Text('Fotos:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (item.fotos.isEmpty)
                const Text('Nenhuma foto.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.fotos
                      .map((p) => Image.file(
                            File(p.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')
          ),
        ],
      ),
    );
  }

  void _editarChecklist(BuildContext context, Checklist item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Checklist'),
        content: const Text('Funcionalidade de edição não implementada.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')
          ),
        ],
      ),
    );
  }
}