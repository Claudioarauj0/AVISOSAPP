import 'package:avisos/models/escala.dart';
import 'package:avisos/screens/escala_screen.dart';
import 'package:avisos/services/storage.dart';
import 'package:avisos/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('marca pessoa em dias e em todos os domingos', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
    await Storage.instance.init();

    // departamentos padrão criados na primeira abertura
    final nomes = Storage.instance.listaDepartamentos().map((d) => d.nome);
    expect(nomes, ['Diaconato', 'DI', 'Louvor', 'Ministros', 'Dirigentes']);

    final dep = Storage.instance.departamentos.buscar('padrao_diaconato')!
      ..pessoas = ['Junior', 'Maria'];

    await tester.pumpWidget(
      MaterialApp(
        theme: temaApp(),
        home: EscalaScreen(departamento: dep, ano: 2026, mes: 10),
      ),
    );

    Escala? escala() =>
        Storage.instance.escalas.buscar(Escala.idPara(dep.id, 2026, 10));

    // seleciona Junior e toca nos dias 10 e 11
    await tester.tap(find.text('Junior'));
    await tester.pump();
    await tester.tap(find.text('10'));
    await tester.tap(find.text('11'));
    await tester.pumpAndSettle();
    expect(escala()!.diaEscala(10)!.pessoas, ['Junior']);
    expect(escala()!.diaEscala(11)!.pessoas, ['Junior']);

    // toca de novo no 11 para desmarcar
    await tester.tap(find.text('11').first);
    await tester.pumpAndSettle();
    expect(escala()!.diaEscala(11), isNull);

    // Maria em todos os domingos (letra D)
    await tester.tap(find.text('Maria'));
    await tester.pump();
    await tester.tap(find.text('D'));
    await tester.pumpAndSettle();
    final domingos = [4, 11, 18, 25];
    for (final d in domingos) {
      expect(escala()!.diaEscala(d)!.pessoas, contains('Maria'));
    }
    expect(escala()!.dias.where((d) => d.pessoas.contains('Maria')).length, 4);
  });
}
