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
import 'checklist_screen.dart';
import 'orcamento_previo_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  final _df = DateFormat('dd/MM/yyyy HH:mm');
  String _search = '';

  // 🎨 Paleta
  static const Color _primaryColor = Color(0xFFCD193C);
  static const Color _backgroundColor = Colors.white;
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF1A1A1A);
  static const Color _secondaryTextColor = Color(0xFF6B7280);

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
      return Image.network(path, width: 90, height: 90, fit: BoxFit.cover);
    }
    return Image.file(File(path), width: 90, height: 90, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final isAdmin = app.role == UserRole.admin;

    final base = isAdmin
        ? app.checklists
        : app.checklists.where((c) => c.createdByUid == app.userUid).toList();
    final checklists = _filter(base);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Histórico de Checklists',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: checklists.isEmpty
                ? Center(
                    child: Text(
                      _search.isEmpty
                          ? 'Nenhum checklist encontrado.'
                          : 'Nenhum resultado para "$_search".',
                      style: const TextStyle(color: _secondaryTextColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: checklists.length,
                    itemBuilder: (_, i) =>
                        _buildChecklistCard(checklists[i], app, isAdmin),
                  ),
          ),
        ],
      ),
    );
  }

  // 🔍 Barra de busca
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextFormField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Buscar por cliente, placa ou carro...',
          hintStyle: const TextStyle(color: _secondaryTextColor),
          prefixIcon: const Icon(Icons.search, color: _secondaryTextColor),
          filled: true,
          fillColor: _cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // 🔹 Card de checklist
  Widget _buildChecklistCard(Checklist c, AppState app, bool isAdmin) {
    final hasOrc =
        c.orcamentoPrevio != null && c.orcamentoPrevio!.trim().isNotEmpty;

    return StatefulBuilder(
      builder: (context, setStateCard) {
        double scale = 1.0;

        return AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: scale,
          curve: Curves.easeOut,
          child: GestureDetector(
            onTapDown: (_) => setStateCard(() => scale = 0.96),
            onTapCancel: () => setStateCard(() => scale = 1.0),
            onTapUp: (_) {
              setStateCard(() => scale = 1.0);
              _mostrarDetalhes(context, c);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cliente + placa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            c.nomeCliente,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Chip(
                          label: Text(
                            c.placa.toUpperCase(),
                            style: const TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: _primaryColor.withOpacity(0.1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    _info(
                      Icons.directions_car_outlined,
                      '${c.marcaCarro} ${c.modeloCarro} (${c.corCarro})',
                    ),
                    _info(
                      Icons.calendar_today_outlined,
                      'Ano: ${c.anoCarro.toString()}',
                    ),
                    if (hasOrc)
                      _info(
                        Icons.request_quote_outlined,
                        'Orçamento prévio cadastrado',
                      ),

                    const Divider(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Por: ${c.createdBy}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _secondaryTextColor,
                              ),
                            ),
                            Text(
                              _df.format(c.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: _secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (isAdmin)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                color: _secondaryTextColor,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChecklistScreen(editing: c),
                                  ),
                                ),
                              ),
                            if (isAdmin)
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: _primaryColor,
                                onPressed: () =>
                                    _confirmDelete(context, app, c),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _info(IconData icon, String text, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _secondaryTextColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _textColor),
            ),
          ),
        ],
      ),
    );
  }

  // ==== MODAL DE DETALHES + ORÇAMENTO + PDF =====================

  void _mostrarDetalhes(BuildContext context, Checklist item) {
    final hasOrc =
        item.orcamentoPrevio != null && item.orcamentoPrevio!.trim().isNotEmpty;
    final dfDataHora = DateFormat('dd/MM/yyyy HH:mm');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Checklist - ${item.placa.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ======== DADOS DO CHECKLIST ========
              _detailRow('Cliente', item.nomeCliente),
              _detailRow('Veículo', '${item.marcaCarro} ${item.modeloCarro}'),
              _detailRow('Ano', item.anoCarro.toString()),
              _detailRow('Cor', item.corCarro),

              const SizedBox(height: 8),
              _detailRow(
                'Observações',
                item.observacoes.isEmpty ? '—' : item.observacoes,
              ),

              const SizedBox(height: 12),

              // ======== FOTOS ========
              const Text(
                'Fotos:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 4),

              if (item.fotos.isEmpty)
                const Text(
                  'Nenhuma foto registrada.',
                  style: TextStyle(color: _secondaryTextColor),
                )
              else
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _fotoWidget(item.fotos[i].path),
                    ),
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemCount: item.fotos.length,
                  ),
                ),

              const SizedBox(height: 12),

              // ======== ORÇAMENTO PRÉVIO ========
              const Text(
                'Orçamento prévio:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),

              const SizedBox(height: 4),

              if (!hasOrc)
                const Text(
                  'Nenhum orçamento cadastrado.',
                  style: TextStyle(color: _secondaryTextColor),
                )
              else ...[
                Text(
                  item.orcamentoPrevio!,
                  style: const TextStyle(color: _textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Por: ${item.orcamentoAutor ?? '-'} em '
                  '${item.orcamentoData != null ? dfDataHora.format(item.orcamentoData!) : '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),

        // ======== BOTÕES DO MODAL (sem alterar estrutura) ========
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),

          // Botão orçamento
          TextButton.icon(
            icon: const Icon(Icons.request_quote_outlined),
            label: Text(
              hasOrc ? 'Ver / editar orçamento' : 'Cadastrar orçamento',
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrcamentoPrevioScreen(checklist: item),
                ),
              );
            },
          ),

          // Botão PDF
          FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _exportChecklistAsPdf(context, item);
            },
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _secondaryTextColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: _textColor)),
        ],
      ),
    );
  }

  // ==== PDF =====================================================

  Future<void> _exportChecklistAsPdf(
    BuildContext context,
    Checklist item,
  ) async {
    final app = AppStateScope.of(context);
    final email = app.userEmail;
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    try {
      final pdf = pw.Document();

      // logo
      final logoBytes = await rootBundle.load('assets/autocenter_logo.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      // ignore: deprecated_member_use
      final primaryPdfColor = PdfColor.fromInt(_primaryColor.value);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => [
            pw.Center(child: pw.Image(logoImage, width: 160)),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Check-list de Veículo',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(height: 2, color: primaryPdfColor),
            pw.SizedBox(height: 10),
            pw.Text(
              'Emitido para: $email',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Gerado em: $nowStr',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 18),

            // DADOS PRINCIPAIS
            pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(110),
                1: pw.FlexColumnWidth(),
              },
              children: [
                _pdfRow('Cliente', item.nomeCliente),
                _pdfRow('Placa', item.placa.toUpperCase()),
                _pdfRow('Veículo', '${item.marcaCarro} ${item.modeloCarro}'),
                _pdfRow('Ano', item.anoCarro.toString()),
                _pdfRow('Cor', item.corCarro),
                _pdfRow('Criado por', item.createdBy),
                _pdfRow('Data do checklist', _df.format(item.createdAt)),
              ],
            ),
            pw.SizedBox(height: 16),

            // Observações
            pw.Text(
              'Observações:',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                item.observacoes.isEmpty ? '—' : item.observacoes,
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
            pw.SizedBox(height: 16),

            // Orçamento
            pw.Text(
              'Orçamento prévio:',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            if (item.orcamentoPrevio == null ||
                item.orcamentoPrevio!.trim().isEmpty)
              pw.Text(
                'Nenhum orçamento cadastrado.',
                style: const pw.TextStyle(fontSize: 11),
              )
            else ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  item.orcamentoPrevio!,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Por: ${item.orcamentoAutor ?? '-'}'
                '${item.orcamentoData != null ? ' em ${_df.format(item.orcamentoData!)}' : ''}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'checklist_${item.placa.toUpperCase()}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.TableRow _pdfRow(String label, String? value) {
    final safe = (value ?? '').trim();
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(safe.isEmpty ? '—' : safe),
        ),
      ],
    );
  }

  // ==== EXCLUSÃO ================================================
  Future<void> _confirmDelete(
    BuildContext context,
    AppState app,
    Checklist c,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir este checklist?'),
        actions: [
          TextButton(
            child: const Text(
              'Cancelar',
              style: TextStyle(color: _secondaryTextColor),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text(
              'Excluir',
              style: TextStyle(color: _primaryColor),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await app.removeChecklist(c);
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checklist excluído com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
