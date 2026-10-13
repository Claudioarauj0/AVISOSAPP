import 'dart:io';

import 'package:avisos/models/aviso.dart';
import 'package:avisos/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera PDF de exemplo', () async {
    await initializeDateFormatting('pt_BR');
    final a = Aviso.novo()
      ..culto = 'Culto de Celebração'
      ..data = DateTime(2026, 10, 4)
      ..tempoLouvor = formatarTempo(30)
      ..ministroLouvor = 'Equipe de Louvor'
      ..musicas = [
        'Grande é o Senhor',
        'Bondade de Deus',
        'Lugar Secreto',
        '',
        '',
      ]
      ..tempoDirecao = '10 min'
      ..dirigente = 'Pr. João'
      ..avisos = [
        'Batismo dia 18/10',
        'Conferência de jovens',
        'Ceia no próximo domingo',
        '',
        '',
      ]
      ..tempoMinistracao = formatarTempo(75)
      ..ministro = 'Pr. Marcos'
      ..avisosFinais = ['Oferta missionária', 'Café após o culto', '', '', '']
      ..ordem = ['avisos', 'louvor', 'ministracao', 'direcao', 'avisosFinais'];
    final bytes = await PdfService.gerar(a);
    expect(bytes.length, greaterThan(1000));
    final saida = Platform.environment['PDF_SAIDA'];
    if (saida != null) File(saida).writeAsBytesSync(bytes);
  });
}
