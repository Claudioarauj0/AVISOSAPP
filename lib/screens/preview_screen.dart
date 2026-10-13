import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/anotacao.dart';
import '../models/aviso.dart';
import '../models/escala.dart';
import '../services/anotacao_pdf.dart';
import '../services/escala_pdf.dart';
import '../services/pdf_service.dart';
import '../theme.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({
    super.key,
    required this.gerar,
    required this.nomeArquivo,
    required this.enviar,
  });

  PreviewScreen.aviso(Aviso a, {Key? key})
    : this(
        key: key,
        gerar: () => PdfService.gerar(a),
        nomeArquivo: PdfService.nomeArquivo(a),
        enviar: () => PdfService.compartilhar(a),
      );

  PreviewScreen.anotacao(Anotacao n, {Key? key})
    : this(
        key: key,
        gerar: () => AnotacaoPdf.gerar(n),
        nomeArquivo: AnotacaoPdf.nomeArquivo(n),
        enviar: () => AnotacaoPdf.compartilhar(n),
      );

  PreviewScreen.escala(Escala e, {Key? key})
    : this(
        key: key,
        gerar: () => EscalaPdf.gerar(e),
        nomeArquivo: EscalaPdf.nomeArquivo(e),
        enviar: () => EscalaPdf.compartilhar(e),
      );

  final Future<Uint8List> Function() gerar;
  final String nomeArquivo;
  final Future<void> Function() enviar;

  @override
  Widget build(BuildContext context) {
    return FundoFuturista(
      child: Scaffold(
        appBar: AppBar(title: const Text('PDF')),
        body: PdfPreview(
          build: (_) => gerar(),
          pdfFileName: nomeArquivo,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          allowSharing: false,
          allowPrinting: true,
          scrollViewDecoration: const BoxDecoration(color: Colors.transparent),
          pdfPreviewPageDecoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Cores.azul.withValues(alpha: 0.35),
                blurRadius: 24,
              ),
            ],
          ),
        ),
        floatingActionButton: BotaoNeon(
          onTap: enviar,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.send_rounded),
              SizedBox(width: 10),
              Text('ENVIAR'),
            ],
          ),
        ),
      ),
    );
  }
}
