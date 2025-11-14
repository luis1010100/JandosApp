import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/app_state.dart';
import '../models/user_role.dart';
import '../models/checklist.dart';
import '../screens/checklist_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  final _df = DateFormat('dd/MM/yyyy HH:mm');
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _search = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Checklist> _filter(List<Checklist> all) {
    if (_search.isEmpty) return all;
    return all.where((c) {
      final t = _search;
      return c.nomeCliente.toLowerCase().contains(t) ||
          c.placa.toLowerCase().contains(t) ||
          c.nomeCarro.toLowerCase().contains(t) ||
          c.modeloCarro.toLowerCase().contains(t) ||
          c.marcaCarro.toLowerCase().contains(t) ||
          c.corCarro.toLowerCase().contains(t);
    }).toList();
  }

  Widget _fotoWidget(String path) {
    final isHttp = path.startsWith('http://') || path.startsWith('https://');
    if (kIsWeb || isHttp) {
      return Image.network(path, width: 100, height: 100, fit: BoxFit.cover);
    }
    return Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final isAdmin = app.role == UserRole.admin;
    final checklists = _filter(app.checklists);

    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Checklists ${isAdmin ? "(Admin)" : ""}'),
      ),
      body: Column(
        children: [
          // 🔍 Campo de pesquisa
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Pesquisar por cliente, placa, carro...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 🔄 Lista em tempo real
          Expanded(
            child: checklists.isEmpty
                ? const Center(child: Text('Nenhum checklist encontrado.'))
                : RefreshIndicator(
                    onRefresh: () async {
                      // nada a fazer: já atualiza automaticamente
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                                Text(
                                  'Observações: ${c.observacoes.isEmpty ? "—" : c.observacoes}',
                                ),
                                Text(
                                  'Criado por: ${c.createdBy} (${c.createdByRole.name})',
                                ),
                                Text('Data: ${_df.format(c.createdAt)}'),
                              ],
                            ),
                            isThreeLine: true,

                            // 🔹 Ações (ver / editar / excluir)
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Ver detalhes',
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () => _mostrarDetalhes(context, c),
                                ),
                                if (isAdmin) ...[
                                  IconButton(
                                    tooltip: 'Editar',
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ChecklistScreen(editing: c),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Excluir',
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Confirmar exclusão'),
                                          content: const Text(
                                            'Deseja realmente excluir este checklist?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Excluir'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        app.removeChecklist(c);
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // === 📄 Modal de detalhes e PDF ===
  void _mostrarDetalhes(BuildContext context, Checklist item) {
    final df = _df;
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
              const Text(
                'Observações:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(item.observacoes.isEmpty ? '—' : item.observacoes),
              const SizedBox(height: 12),
              const Text(
                'Fotos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (item.fotos.isEmpty)
                const Text('Nenhuma foto.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.fotos.map((p) => _fotoWidget(p.path)).toList(),
                ),
              const SizedBox(height: 12),
              Text(
                'Criado por: ${item.createdBy} (${item.createdByRole.name})',
              ),
              Text('Data: ${df.format(item.createdAt)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _exportChecklistAsPdf(context, item);
            },
            child: const Text('Exportar PDF'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportChecklistAsPdf(
    BuildContext context,
    Checklist item,
  ) async {
    final app = AppStateScope.of(context);
    final email = app.userEmail;
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    try {
      final pdf = pw.Document();
      final logoBytes = await rootBundle.load('assets/autocenter_logo.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => [
            pw.Center(child: pw.Image(logoImage, width: 140)),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Relatório de Checklist',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(height: 2, color: PdfColor.fromInt(0x00CD193C)),
            pw.SizedBox(height: 12),
            pw.Text('Emitido para: $email', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Gerado em: $now', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 20),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Table(
                columnWidths: const {
                  0: pw.FixedColumnWidth(110),
                  1: pw.FlexColumnWidth(),
                },
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  _pdfRow('Cliente', item.nomeCliente),
                  _pdfRow('Carro', item.nomeCarro),
                  _pdfRow('Modelo', item.modeloCarro),
                  _pdfRow('Marca', item.marcaCarro),
                  _pdfRow('Ano', '${item.anoCarro}'),
                  _pdfRow('Cor', item.corCarro),
                  _pdfRow('Placa', item.placa),
                  _pdfRow('Criado por', '${item.createdBy} (${item.createdByRole.name})'),
                  _pdfRow('Data de Criação', _df.format(item.createdAt)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Observações:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                item.observacoes.isEmpty ? '—' : item.observacoes,
                maxLines: 20,
                overflow: pw.TextOverflow.span,
              ),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'checklist_${item.placa}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: $e')),
      );
    }
  }

  pw.TableRow _pdfRow(String label, String? value) {
    final safe = (value ?? '').trim();
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(safe.isEmpty ? '—' : safe),
        ),
      ],
    );
  }
}
