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

  // --- 🎨 NOSSAS CONSTANTES DE DESIGN (baseadas no seu briefing) ---
  static const Color _backgroundColor = Color(0xFFF6F7F9);
  static const Color _cardColor = Colors.white;
  static const Color _primaryColor = Color(0xFFFF6600); // Laranja (para consistência)
  static const Color _textColor = Color(0xFF1A1A1A);
  static const Color _secondaryTextColor = Color(0xFF6B7280);
  // --- FIM DAS CONSTANTES DE DESIGN ---

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
    // 🔹 Filtra a lista baseada no role ANTES de passar para o filtro de busca
    final baseChecklists = isAdmin
        ? app.checklists
        // 🔹 Filtro para mecânico: mostra apenas os dele
        : app.checklists.where((c) => c.createdByUid == app.userUid).toList();

    final checklists = _filter(baseChecklists);

    return Scaffold(
      // 1. ✅ Cor de fundo e AppBar
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Histórico de Checklists',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold, // semibold
            fontSize: 22,
          ),
        ),
        backgroundColor: _cardColor,
        foregroundColor: _textColor,
        elevation: 1.0,
      ),
      body: Column(
        children: [
          // 2. ✅ Campo de pesquisa estilizado
          _buildSearchBar(),

          // 3. ✅ Layout Responsivo (Grid/Lista)
          Expanded(
            child: checklists.isEmpty
                ? Center(
                    child: Text(
                    _search.isEmpty
                        ? 'Nenhum checklist encontrado.'
                        : 'Nenhum resultado para "$_search"',
                    style: TextStyle(color: _secondaryTextColor),
                  ))
                : RefreshIndicator(
                    onRefresh: () async {
                      // A lista já atualiza via Stream,
                      // mas manter isso é bom para o usuário
                    },
                    // 4. ✅ LayoutBuilder para responsividade
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Define o breakpoint
                        final bool isWideScreen = constraints.maxWidth > 600;

                        if (isWideScreen) {
                          // --- MODO TABLET (GRID) ---
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 480, // Limite de 480dp
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.8, // Ajuste para altura
                            ),
                            itemCount: checklists.length,
                            itemBuilder: (context, index) {
                              return _buildChecklistCard(
                                checklists[index],
                                app,
                                isAdmin,
                              );
                            },
                          );
                        } else {
                          // --- MODO CELULAR (LISTA) ---
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: checklists.length,
                            itemBuilder: (context, index) {
                              return _buildChecklistCard(
                                checklists[index],
                                app,
                                isAdmin,
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 2. ✅ Helper do Campo de pesquisa estilizado
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextFormField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Buscar por cliente, placa ou carro...',
          hintStyle: TextStyle(color: _secondaryTextColor),
          prefixIcon: Icon(Icons.search, color: _secondaryTextColor),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: _secondaryTextColor),
                  onPressed: () {
                    _searchCtrl.clear();
                    // setState é chamado pelo listener
                  },
                )
              : null,
          filled: true,
          fillColor: _cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none, // Sem borda, design "flutuante"
          ),
        ),
      ),
    );
  }

  /// 5. ✅ O NOVO CARD REATORADO
  Widget _buildChecklistCard(Checklist c, AppState app, bool isAdmin) {
    // 🔹 MUDANÇA: Substituído Card por Container para sombra customizada
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Apenas para ListView
      decoration: BoxDecoration( // 🔹 MUDANÇA: Sombra mais suave
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), // Sombra mais suave
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bloco 1: Título e Placa ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    c.nomeCliente,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold, // semibold
                      color: _textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // ✅ Chip para Placa
                Chip(
                  label: Text(
                    c.placa.toUpperCase(),
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- Bloco 2: Informações ---
            _buildInfoRow(
              Icons.directions_car_outlined,
              '${c.marcaCarro} ${c.modeloCarro} (${c.corCarro})',
            ),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Ano: ${c.anoCarro}',
            ),
            // 🔹 MUDANÇA: Observações com maxLines: 1 para card mais limpo
            _buildInfoRow(
              Icons.notes_outlined,
              c.observacoes.isEmpty ? "Nenhuma observação" : c.observacoes,
              maxLines: 1, // MUDADO DE 2 PARA 1
            ),

            const Divider(height: 24),

            // --- Bloco 3: Metadados e Ações ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✅ Metadados (Criado por, Data)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Por: ${c.createdBy}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryTextColor,
                      ),
                    ),
                    Text(
                      _df.format(c.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                // ✅ Ações (com Tooltip e movidas para baixo)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Ver detalhes',
                      child: IconButton(
                        icon: Icon(Icons.visibility_outlined,
                            color: _secondaryTextColor),
                        onPressed: () => _mostrarDetalhes(context, c),
                      ),
                    ),
                    if (isAdmin) ...[
                      Tooltip(
                        message: 'Editar',
                        child: IconButton(
                          icon: Icon(Icons.edit_outlined,
                              color: _secondaryTextColor),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChecklistScreen(editing: c),
                              ),
                            );
                          },
                        ),
                      ),
                      Tooltip(
                        message: 'Excluir',
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _confirmDelete(context, app, c),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Helper para linhas de informação (Item 2)
  Widget _buildInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Padding(
      // 🔹 MUDANÇA: Mais espaçamento vertical
      padding: const EdgeInsets.only(bottom: 8.0), // MUDADO DE 6.0 PARA 8.0
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _secondaryTextColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: _textColor),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Helper para o diálogo de exclusão (limpando o build)
  Future<void> _confirmDelete(BuildContext context, AppState app, Checklist c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este checklist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: _secondaryTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await app.removeChecklist(c);
        if (!mounted) return;
        // ✅ Feedback com SnackBar (Item 6)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checklist excluído com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // === 📄 Modal de detalhes e PDF (Refatorado) ===
  void _mostrarDetalhes(BuildContext context, Checklist item) {
    final df = _df;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        // ✅ Estilo do Modal
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Detalhes do Checklist',
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        
        // 🔹 MUDANÇA: Layout do modal refeito para 2 colunas
        content: SizedBox( // Dando uma largura máxima para o modal
          width: 500, // Bom para responsividade em tablet
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Bloco 1: Cliente e Veículo (em colunas) ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildModalInfoRow('Cliente', item.nomeCliente)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModalInfoRow('Placa', item.placa.toUpperCase())),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildModalInfoRow('Carro', item.nomeCarro)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModalInfoRow('Ano', item.anoCarro.toString())),
                  ],
                ),
                const SizedBox(height: 8),
                 Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildModalInfoRow('Marca', item.marcaCarro)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModalInfoRow('Modelo', item.modeloCarro)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildModalInfoRow('Cor', item.corCarro), // Cor sozinha

                const Divider(height: 24),
                
                // --- Bloco 2: Observações ---
                _buildModalInfoRow(
                    'Observações', item.observacoes.isEmpty ? '—' : item.observacoes),
                
                const Divider(height: 24),
                
                // --- Bloco 3: Metadados ---
                Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Expanded(child: _buildModalInfoRow('Criado por', '${item.createdBy} (${item.createdByRole.name})')),
                     const SizedBox(width: 16),
                     Expanded(child: _buildModalInfoRow('Data', df.format(item.createdAt))),
                   ],
                ),
                const SizedBox(height: 16),
                
                // --- Bloco 4: Fotos ---
                const Text(
                  'FOTOS:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (item.fotos.isEmpty)
                  const Text('Nenhuma foto.',
                      style: TextStyle(color: _secondaryTextColor))
                else
                  // ✅ Lista de fotos horizontal
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: item.fotos.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _fotoWidget(item.fotos[i].path),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          // ✅ Botões do Modal estilizados
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar', style: TextStyle(color: _secondaryTextColor)),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf, size: 18),
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

  /// ✅ Helper para as linhas de info do Modal
  Widget _buildModalInfoRow(String label, String value) {
    return Padding(
      // 🔹 MUDANÇA: Mais espaçamento vertical no modal
      padding: const EdgeInsets.symmetric(vertical: 6.0), // MUDADO DE 4.0 PARA 6.0
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: _textColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- ⚠️ Lógica de PDF (Não alterada, funcionalidade mantida) ---
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
            // ✅ Cor do PDF alterada para o laranja
            pw.Container(
                height: 2,
                color: PdfColor.fromHex(_primaryColor.value.toRadixString(16))),
            pw.SizedBox(height: 12),
            pw.Text('Emitido para: $email',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Gerado em: $now',
                style: const pw.TextStyle(fontSize: 10)),
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
                  _pdfRow('Criado por',
                      '${item.createdBy} (${item.createdByRole.name})'),
                  _pdfRow('Data de Criação', _df.format(item.createdAt)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Observações:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
          child: pw.Text('$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(safe.isEmpty ? '—' : safe),
        ),
      ],
    );
  }
}