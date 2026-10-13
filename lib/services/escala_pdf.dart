import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/escala.dart';
import 'pdf_service.dart';

const _linhaClara = PdfColor.fromInt(0xFFF1F5FF);
const _borda = PdfColor.fromInt(0xFFD5DEF5);

String nomeMes(int ano, int mes) {
  final s = DateFormat('MMMM yyyy', 'pt_BR').format(DateTime(ano, mes));
  return s[0].toUpperCase() + s.substring(1);
}

String diaSemana(DateTime d) {
  final s = DateFormat('EEEE', 'pt_BR').format(d);
  return s[0].toUpperCase() + s.substring(1);
}

class EscalaPdf {
  static Future<Uint8List> gerar(Escala e) async {
    final logo = await PdfComum.logo();
    final doc = pw.Document(title: 'Escala ${e.departamentoNome}');
    final dias = e.ordenados.where((d) => d.pessoas.isNotEmpty).toList();
    final temObs = dias.any((d) => d.obs.trim().isNotEmpty);

    // A faixa azul é desenhada no fundo da página (de ponta a ponta); aqui
    // vai só o conteúdo, dentro das margens, para a tabela poder quebrar
    // página normalmente.
    const alturaFaixa = 112.0;
    final cabecalho = pw.Container(
      height: alturaFaixa,
      margin: const pw.EdgeInsets.only(bottom: 22),
      child: pw.Row(
        children: [
          pw.Image(logo, height: 58),
          pw.SizedBox(width: 18),
          pw.Expanded(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ESCALA',
                  style: const pw.TextStyle(
                    color: pdfCiano,
                    fontSize: 9,
                    letterSpacing: 3,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  e.departamentoNome.toUpperCase(),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  nomeMes(e.ano, e.mes),
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    pw.Widget celula(
      String texto, {
      bool cabecalho = false,
      bool negrito = false,
      pw.Alignment alinhamento = pw.Alignment.centerLeft,
    }) => pw.Container(
      alignment: alinhamento,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          color: cabecalho ? PdfColors.white : PdfColors.black,
          fontWeight: cabecalho || negrito ? pw.FontWeight.bold : null,
          fontSize: cabecalho ? 10 : 11.5,
          letterSpacing: cabecalho ? 1.2 : 0,
        ),
      ),
    );

    final tabela = pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _borda, width: 0.6),
        bottom: pw.BorderSide(color: _borda, width: 0.6),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(58),
        1: const pw.FixedColumnWidth(95),
        2: const pw.FlexColumnWidth(3),
        if (temObs) 3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            gradient: pw.LinearGradient(colors: [pdfMarinho, pdfAzul]),
          ),
          repeat: true,
          children: [
            celula('DATA', cabecalho: true, alinhamento: pw.Alignment.center),
            celula('DIA', cabecalho: true),
            celula('ESCALADOS', cabecalho: true),
            if (temObs) celula('OBSERVAÇÃO', cabecalho: true),
          ],
        ),
        for (var i = 0; i < dias.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isOdd ? _linhaClara : PdfColors.white,
            ),
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              celula(
                DateFormat('dd/MM').format(e.data(dias[i].dia)),
                negrito: true,
                alinhamento: pw.Alignment.center,
              ),
              celula(diaSemana(e.data(dias[i].dia))),
              celula(dias[i].pessoas.join(', ')),
              if (temObs) celula(dias[i].obs.trim()),
            ],
          ),
      ],
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40),
          theme: await PdfComum.tema(),
          buildBackground: (ctx) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Column(
              children: [
                pw.Container(
                  height: ctx.pageNumber == 1 ? alturaFaixa : 6,
                  decoration: const pw.BoxDecoration(
                    gradient: pdfGradienteCabecalho,
                  ),
                ),
              ],
            ),
          ),
        ),
        header: (ctx) =>
            ctx.pageNumber == 1 ? cabecalho : pw.SizedBox(height: 26),
        build: (ctx) => [
          dias.isEmpty ? pw.Text('Nenhum dia escalado.') : tabela,
        ],
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 18),
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

  static String nomeArquivo(Escala e) => PdfComum.limparNome([
    'escala',
    e.departamentoNome,
    DateFormat('MM-yyyy').format(DateTime(e.ano, e.mes)),
  ]);

  static Future<void> compartilhar(Escala e) async {
    await PdfComum.compartilhar(
      await gerar(e),
      nomeArquivo(e),
      'Escala ${e.departamentoNome} - ${nomeMes(e.ano, e.mes)}',
    );
  }
}
