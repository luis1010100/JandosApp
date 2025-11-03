import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // <- p/ detectar Web
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_database/firebase_database.dart';

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

  static const int _pageSize = 30;
  final List<Checklist> _items = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _cursorOldestIso;
  String _search = '';

  DatabaseReference get _db => AppStateScope.of(context).database;

  @override
  void initState() {
    super.initState();
    // 🔹 Evita usar InheritedWidget antes do 1º frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final text = _searchCtrl.text.trim().toLowerCase();
      if (text != _search) setState(() => _search = text);
    });
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _items.clear();
      _cursorOldestIso = null;
      _hasMore = true;
    });

    try {
      final role = AppStateScope.of(context).role;
      final currentUser = AppStateScope.of(context).userName;

      final snap = await _db
          .child('checklists')
          .orderByChild('createdAt')
          .limitToLast(_pageSize)
          .get()
          .timeout(const Duration(seconds: 12)); // ⏱️ timeout

      final list = <Checklist>[];
      if (snap.exists) {
        for (final child in snap.children) {
          final map = Map<String, dynamic>.from(child.value as Map);
          final c = Checklist.fromMap(map);
          if (role == UserRole.mechanic && c.createdBy != currentUser) continue;
          list.add(c);
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      setState(() {
        _items.addAll(list);
        if (list.isNotEmpty) {
          _cursorOldestIso = list.last.createdAt.toIso8601String();
        }
        _hasMore = list.length == _pageSize;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInitialLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao carregar: $e')));
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore || _cursorOldestIso == null) return;
    setState(() => _isLoadingMore = true);

    try {
      final role = AppStateScope.of(context).role;
      final currentUser = AppStateScope.of(context).userName;

      final snap = await _db
          .child('checklists')
          .orderByChild('createdAt')
          .endAt(_cursorOldestIso) // inclusivo
          .limitToLast(_pageSize + 1)
          .get()
          .timeout(const Duration(seconds: 12)); // ⏱️

      final page = <Checklist>[];
      if (snap.exists) {
        for (final child in snap.children) {
          final map = Map<String, dynamic>.from(child.value as Map);
          final c = Checklist.fromMap(map);
          if (role == UserRole.mechanic && c.createdBy != currentUser) continue;
          page.add(c);
        }
        page.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      // remove possível duplicata entre páginas
      if (page.isNotEmpty && _items.isNotEmpty && page.first.id == _items.last.id) {
        page.removeAt(0);
      }

      setState(() {
        _items.addAll(page);
        if (page.isNotEmpty) {
          _cursorOldestIso = page.last.createdAt.toIso8601String();
        }
        _hasMore = page.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao carregar mais: $e')));
    }
  }

  List<Checklist> get _filtered {
    if (_search.isEmpty) return _items;
    return _items.where((c) {
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
    // ^ no Web não use File(...)
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AppStateScope.of(context).role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Checklists ${isAdmin ? "(Admin)" : ""}'),
      ),
      body: Column(
        children: [
          // 🔎 Pesquisa em tempo real
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // ⏳ Loading inicial / lista / paginação
          if (_isInitialLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_filtered.isEmpty)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInitial,
                child: ListView(
                  children: const [
                    SizedBox(height: 160),
                    Center(child: Text('Nenhum checklist encontrado.')),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInitial,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _filtered.length + 1, // rodapé "carregar mais"
                  itemBuilder: (context, index) {
                    if (index == _filtered.length) {
                      if (_hasMore) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: _isLoadingMore
                                ? const CircularProgressIndicator()
                                : OutlinedButton.icon(
                                    onPressed: _loadMore,
                                    icon: const Icon(Icons.expand_more),
                                    label: const Text('Carregar mais'),
                                  ),
                          ),
                        );
                      } else {
                        return const SizedBox(height: 24);
                      }
                    }

                    final c = _filtered[index];
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
                            Text('Data: ${_df.format(c.createdAt)}'),
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
                                  AppStateScope.of(context).removeChecklist(c);
                                  setState(() => _items.removeWhere((e) => e.id == c.id));
                                }
                              },
                            ),
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

  // ===== Detalhes + Exportar PDF =====
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
                  children: item.fotos.map((p) => _fotoWidget(p.path)).toList(),
                ),
              const SizedBox(height: 12),
              Text('Criado por: ${item.createdBy} (${item.createdByRole.name})'),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }

  // ===== Exporta PDF (Web baixa, Mobile compartilha) =====
  Future<void> _exportChecklistAsPdf(BuildContext context, Checklist item) async {
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
            pw.Center(child: pw.Text('Relatório de Checklist',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
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
                columnWidths: const { 0: pw.FixedColumnWidth(110), 1: pw.FlexColumnWidth() },
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
                  _pdfRow('Data de Criação', DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt)),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
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
          child: pw.Text(safe.isEmpty ? '—' : safe, maxLines: 3, overflow: pw.TextOverflow.span),
        ),
      ],
    );
  }
}
