import 'dart:io';

import 'package:avisos/models/anotacao.dart';
import 'package:avisos/services/anotacao_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera PDF de anotação com várias páginas', () async {
    await initializeDateFormatting('pt_BR');
    const paragrafo =
        'Porque Deus amou o mundo de tal maneira que deu o seu Filho '
        'unigênito, para que todo aquele que nele crê não pereça, mas tenha a '
        'vida eterna. Anotações da reunião de líderes — “planejamento” do '
        'trimestre, escalas de louvor, recepção e intercessão.';
    final n = Anotacao.nova()
      ..titulo = 'Reunião de Líderes'
      ..corpo = List.filled(14, paragrafo).join('\n\n')
      ..atualizadoEm = DateTime(2026, 10, 2, 15, 42);
    final bytes = await AnotacaoPdf.gerar(n);
    expect(bytes.length, greaterThan(1000));
    final saida = Platform.environment['PDF_SAIDA'];
    if (saida != null) File(saida).writeAsBytesSync(bytes);
  });
}
