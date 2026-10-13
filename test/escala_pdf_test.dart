import 'dart:io';

import 'package:avisos/models/escala.dart';
import 'package:avisos/services/escala_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera PDF de escala com o mês inteiro', () async {
    await initializeDateFormatting('pt_BR');
    const nomes = ['Junior', 'Maria', 'Carlos', 'Ana', 'Pedro'];
    final e = Escala(
      departamentoId: 'padrao_diaconato',
      departamentoNome: 'Diaconato',
      ano: 2026,
      mes: 10,
      dias: [
        for (var d = 1; d <= 31; d++)
          DiaEscala(
            dia: d,
            pessoas: [nomes[d % 5], nomes[(d + 2) % 5]],
            obs: d % 7 == 4 ? 'Culto da noite' : '',
          ),
      ],
    );
    final bytes = await EscalaPdf.gerar(e);
    expect(bytes.length, greaterThan(1000));
    final saida = Platform.environment['PDF_SAIDA_ESCALA'];
    if (saida != null) File(saida).writeAsBytesSync(bytes);
  });
}
