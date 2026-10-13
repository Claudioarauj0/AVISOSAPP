import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/aviso.dart';
import '../widgets/logo.dart';

const pdfMarinho = PdfColor.fromInt(0xFF0A1A4A);
const pdfMarinhoEscuro = PdfColor.fromInt(0xFF020817);
const pdfAzul = PdfColor.fromInt(0xFF2F6BFF);
const pdfCiano = PdfColor.fromInt(0xFF4FD8FF);
const pdfCinza = PdfColor.fromInt(0xFF5A6A8C);

/// Degradê da faixa de cabeçalho dos PDFs.
const pdfGradienteCabecalho = pw.LinearGradient(
  begin: pw.Alignment.topLeft,
  end: pw.Alignment.bottomRight,
  colors: [pdfMarinhoEscuro, pdfMarinho, PdfColor.fromInt(0xFF13308A)],
);

String formatarData(DateTime? d) {
  if (d == null) return '';
  final dia = DateFormat('EEEE', 'pt_BR').format(d);
  return '${DateFormat('dd/MM/yyyy').format(d)} - '
      '${dia[0].toUpperCase()}${dia.substring(1)}';
}

/// Recursos comuns aos PDFs (fontes, logo, envio).
class PdfComum {
  static pw.ThemeData? _tema;
  static pw.MemoryImage? _logo;

  /// Roboto embutida: cobre acentos, aspas curvas, travessões etc.
  static Future<pw.ThemeData> tema() async {
    if (_tema != null) return _tema!;
    final regular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final negrito = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    return _tema = pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(negrito),
    ).copyWith(defaultTextStyle: const pw.TextStyle(fontSize: 12));
  }

  static Future<pw.MemoryImage> logo() async {
    if (_logo != null) return _logo!;
    final bytes = await rootBundle.load(logoBranca);
    return _logo = pw.MemoryImage(bytes.buffer.asUint8List());
  }

  static String limparNome(List<String> partes) =>
      '${partes.where((p) => p.trim().isNotEmpty).join('_').replaceAll(RegExp(r'[^\w\-À-ÿ ]'), '').trim().replaceAll(RegExp(r'\s+'), '_')}.pdf';

  /// Grava o PDF e abre o menu de compartilhamento (WhatsApp aparece nele).
  static Future<void> compartilhar(
    Uint8List bytes,
    String nomeArquivo,
    String legenda,
  ) async {
    final dir = await getTemporaryDirectory();
    final arquivo = File('${dir.path}/$nomeArquivo');
    await arquivo.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(arquivo.path, mimeType: 'application/pdf')],
        text: legenda,
        subject: 'Verbo Malvinas',
      ),
    );
  }
}

class PdfService {
  static Future<Uint8List> gerar(Aviso a) async {
    final logo = await PdfComum.logo();
    final doc = pw.Document(title: 'Verbo Malvinas');

    pw.Widget titulo(String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const pw.BoxDecoration(
              gradient: pw.LinearGradient(colors: [pdfMarinho, pdfAzul]),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              t.toUpperCase(),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              height: 1.2,
              margin: const pw.EdgeInsets.only(left: 6),
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [pdfCiano, PdfColors.white],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    pw.Widget linha(String rotulo, String valor) => valor.trim().isEmpty
        ? pw.SizedBox()
        : pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: '$rotulo: ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: pdfMarinho,
                    ),
                  ),
                  pw.TextSpan(text: valor.trim()),
                ],
              ),
            ),
          );

    List<pw.Widget> itens(List<String> lista, {bool numerar = false}) {
      final validos = lista.where((s) => s.trim().isNotEmpty).toList();
      return [
        for (var i = 0; i < validos.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 18,
                  child: pw.Text(
                    numerar ? '${i + 1}.' : '-',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: pdfAzul,
                    ),
                  ),
                ),
                pw.Expanded(child: pw.Text(validos[i].trim())),
              ],
            ),
          ),
      ];
    }

    bool algum(List<String> l) => l.any((s) => s.trim().isNotEmpty);

    List<pw.Widget> secao(String chave) => switch (chave) {
      'louvor' when algum([a.tempoLouvor, a.ministroLouvor, ...a.musicas]) => [
        titulo('Louvor'),
        linha('Tempo de louvor', a.tempoLouvor),
        linha('Ministro de louvor', a.ministroLouvor),
        ...itens(a.musicas, numerar: true),
      ],
      'direcao' when algum([a.tempoDirecao, a.dirigente]) => [
        titulo('Direção'),
        linha('Tempo de direção', a.tempoDirecao),
        linha('Dirigente', a.dirigente),
      ],
      'avisos' when algum(a.avisos) => [titulo('Avisos'), ...itens(a.avisos)],
      'ministracao' when algum([a.tempoMinistracao, a.ministro]) => [
        titulo('Ministração'),
        linha('Tempo', a.tempoMinistracao),
        linha('Ministro', a.ministro),
      ],
      'avisosFinais' when algum(a.avisosFinais) => [
        titulo('Avisos Finais'),
        ...itens(a.avisosFinais),
      ],
      _ => const [],
    };

    final cabecalho = pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(40, 22, 40, 22),
      decoration: const pw.BoxDecoration(gradient: pdfGradienteCabecalho),
      child: pw.Row(
        children: [
          pw.Image(logo, height: 62),
          pw.SizedBox(width: 18),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INFORMATIVOS',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                pw.Text(
                  'VERBO DA VIDA  |  MALVINAS',
                  style: const pw.TextStyle(
                    color: pdfCiano,
                    fontSize: 9,
                    letterSpacing: 2,
                  ),
                ),
                if (a.culto.trim().isNotEmpty || a.data != null)
                  pw.SizedBox(height: 8),
                if (a.culto.trim().isNotEmpty)
                  pw.Text(
                    a.culto.trim(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                if (a.data != null)
                  pw.Text(
                    formatarData(a.data),
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: await PdfComum.tema(),
        header: (ctx) => ctx.pageNumber == 1
            ? cabecalho
            : pw.Container(height: 6, color: pdfMarinho),
        // cada bloco fica solto para o PDF poder quebrar página entre eles
        // seções na ordem escolhida no formulário
        build: (ctx) =>
            [
                  pw.SizedBox(height: 6),
                  for (final chave in a.ordem) ...secao(chave),
                ]
                .map(
                  (w) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                    child: w,
                  ),
                )
                .toList(),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(40, 0, 40, 18),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Verbo Malvinas',
            style: const pw.TextStyle(fontSize: 8, color: pdfCinza),
          ),
        ),
      ),
    );

    return doc.save();
  }

  static String nomeArquivo(Aviso a) => PdfComum.limparNome([
    'avisos',
    a.culto,
    if (a.data != null) DateFormat('dd-MM-yyyy').format(a.data!),
  ]);

  static Future<void> compartilhar(Aviso a) async {
    final legenda = [
      'Avisos${a.culto.trim().isEmpty ? '' : ' - ${a.culto.trim()}'}',
      if (a.data != null) formatarData(a.data),
    ].join('\n');
    await PdfComum.compartilhar(await gerar(a), nomeArquivo(a), legenda);
  }
}
