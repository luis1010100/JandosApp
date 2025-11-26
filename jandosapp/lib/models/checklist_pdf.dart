import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/checklist.dart';

class ChecklistPdfGenerator {
  /// Gera o PDF seguindo o estilo antigo + logo
  static Future<pw.Document> generate(Checklist c) async {
    final pdf = pw.Document();

    // ==== CARREGA LOGO ====
    final logoBytes = File('/mnt/data/Auto center.png').readAsBytesSync();
    final logo = pw.MemoryImage(logoBytes);

    // ==== ESTILOS ====
    final titleStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#CD193C'),
    );

    final labelStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#1B1B1B'),
    );

    final valueStyle = pw.TextStyle(
      fontSize: 12,
      color: PdfColor.fromHex('#333333'),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),

        build: (context) => [
          // ============================
          //          CABEÇALHO
          // ============================
          pw.Center(child: pw.Image(logo, width: 180)),

          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              "CHECKLIST COMPLETO",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#CD193C'),
              ),
            ),
          ),

          pw.Divider(thickness: 1, color: PdfColor.fromHex('#CD193C')),
          pw.SizedBox(height: 16),

          // ============================
          //         DADOS DO CLIENTE
          // ============================
          pw.Text("Dados do Cliente", style: titleStyle),
          pw.SizedBox(height: 8),

          _row("Nome:", c.nomeCliente, labelStyle, valueStyle),
          _row("Placa:", c.placa.toUpperCase(), labelStyle, valueStyle),
          _row(
            "Modelo:",
            "${c.marcaCarro} ${c.modeloCarro}",
            labelStyle,
            valueStyle,
          ),
          _row("Ano:", c.anoCarro.toString(), labelStyle, valueStyle),
          _row("Cor:", c.corCarro, labelStyle, valueStyle),

          pw.SizedBox(height: 16),
          pw.Text("Observações", style: titleStyle),
          pw.SizedBox(height: 6),
          pw.Text(
            c.observacoes.isEmpty ? "Nenhuma." : c.observacoes,
            style: valueStyle,
          ),

          pw.SizedBox(height: 20),

          // ============================
          //         ORÇAMENTO PRÉVIO
          // ============================
          if (c.orcamentoPrevio != null) ...[
            pw.Divider(),
            pw.Text("ORÇAMENTO PRÉVIO", style: titleStyle),
            pw.SizedBox(height: 8),

            _row(
              "Criado por:",
              c.orcamentoAutor ?? "-",
              labelStyle,
              valueStyle,
            ),
            _row(
              "Data:",
              c.orcamentoData != null
                  ? "${c.orcamentoData!.day}/${c.orcamentoData!.month}/${c.orcamentoData!.year}"
                  : "-",
              labelStyle,
              valueStyle,
            ),

            pw.SizedBox(height: 12),
            pw.Text(c.orcamentoPrevio!, style: valueStyle),
            pw.SizedBox(height: 20),
          ],

          // ============================
          //           FOTOS
          // ============================
          pw.Text("Fotos do Checklist", style: titleStyle),
          pw.SizedBox(height: 10),

          if (c.fotos.isEmpty)
            pw.Text("Nenhuma foto adicionada.", style: valueStyle)
          else
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: c.fotos.map((p) {
                try {
                  final bytes = File(p.path).readAsBytesSync();
                  final img = pw.MemoryImage(bytes);

                  return pw.Container(
                    width: 150,
                    height: 150,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColor.fromHex('#CD193C')),
                    ),
                    child: pw.Image(img, fit: pw.BoxFit.cover),
                  );
                } catch (e) {
                  return pw.Text("Erro ao carregar imagem");
                }
              }).toList(),
            ),
        ],
      ),
    );

    return pdf;
  }

  /// Linha padrão (label: valor)
  static pw.Widget _row(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: labelStyle),
          pw.SizedBox(width: 6),
          pw.Expanded(child: pw.Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}
