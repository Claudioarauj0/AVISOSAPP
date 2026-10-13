import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/anotacao.dart';
import 'pdf_service.dart';

String formatarSalvo(DateTime d) =>
    'Salvo em ${DateFormat('dd/MM/yyyy', 'pt_BR').format(d)} às '
    '${DateFormat('HH:mm').format(d)}';

class AnotacaoPdf {
  static Future<Uint8List> gerar(Anotacao n) async {
    final logo = await PdfComum.logo();
    final doc = pw.Document(title: n.tituloOuPadrao);

    // Cabeçalho completo na 1ª página; nas demais, faixa fina com o título.
    pw.Widget cabecalho(pw.Context ctx) {
      if (ctx.pageNumber > 1) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          padding: const pw.EdgeInsets.fromLTRB(50, 10, 50, 10),
          decoration: const pw.BoxDecoration(gradient: pdfGradienteCabecalho),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  n.tituloOuPadrao,
                  maxLines: 1,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              pw.Text(
                formatarSalvo(n.atualizadoEm),
                style: const pw.TextStyle(color: pdfCiano, fontSize: 8),
              ),
            ],
          ),
        );
      }
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        padding: const pw.EdgeInsets.fromLTRB(50, 22, 50, 22),
        decoration: const pw.BoxDecoration(gradient: pdfGradienteCabecalho),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ANOTAÇÕES',
                    style: const pw.TextStyle(
                      color: pdfCiano,
                      fontSize: 9,
                      letterSpacing: 3,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    n.tituloOuPadrao,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    formatarSalvo(n.atualizadoEm),
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Image(logo, height: 50),
          ],
        ),
      );
    }

    // Parágrafos separados por linha em branco; cada um justificado.
    final paragrafos = n.corpo
        .replaceAll('\r\n', '\n')
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trimRight())
        .where((p) => p.trim().isNotEmpty);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: await PdfComum.tema(),
        header: cabecalho,
        build: (ctx) => [
          for (final p in paragrafos)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(50, 0, 50, 10),
              child: pw.Text(
                p,
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
              ),
            ),
        ],
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(50, 0, 50, 18),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Verbo Malvinas',
                style: const pw.TextStyle(fontSize: 8, color: pdfCinza),
              ),
              pw.Text(
                '${ctx.pageNumber}/${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: pdfCinza),
              ),
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }

  static String nomeArquivo(Anotacao n) => PdfComum.limparNome([
    'anotacao',
    n.titulo,
    DateFormat('dd-MM-yyyy_HH-mm').format(n.atualizadoEm),
  ]);

  static Future<void> compartilhar(Anotacao n) async {
    await PdfComum.compartilhar(
      await gerar(n),
      nomeArquivo(n),
      '${n.tituloOuPadrao}\n${formatarSalvo(n.atualizadoEm)}',
    );
  }
}
