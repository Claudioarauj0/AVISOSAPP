import 'package:avisos/models/aviso.dart';
import 'package:avisos/screens/form_screen.dart';
import 'package:avisos/services/storage.dart';
import 'package:avisos/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('formata e lê tempos', () {
    expect(formatarTempo(30), '30 min');
    expect(formatarTempo(60), '1h');
    expect(formatarTempo(75), '1h 15min');
    expect(minutosDe('1h 15min'), 75);
    expect(minutosDe('30 min'), 30);
    expect(minutosDe('30 minutos'), 30);
    expect(minutosDe('45'), 45);
    expect(minutosDe('2h'), 120);
    expect(minutosDe(''), isNull);
  });

  test('ordem antiga/incompleta é completada', () {
    expect(normalizarOrdem(null), secoesPadrao);
    expect(normalizarOrdem(['avisos', 'xyz', 'avisos']), [
      'avisos',
      'louvor',
      'direcao',
      'ministracao',
      'avisosFinais',
    ]);
    // aviso salvo antes desta versão (sem "ordem") abre na ordem padrão
    final antigo = Aviso.fromJson({'id': '1', 'culto': 'x'});
    expect(antigo.ordem, secoesPadrao);
  });

  testWidgets('tempo pelo seletor e seção arrastada', (tester) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
    await Storage.instance.init();

    final a = Aviso.novo()..culto = 'Culto';
    await Storage.instance.avisos.salvar(a);
    await tester.pumpWidget(MaterialApp(
      theme: temaApp(),
      home: FormScreen(aviso: a),
    ));
    await tester.pumpAndSettle();

    // tempo: não é campo de texto, abre o seletor
    await tester.tap(find.text('Tempo de louvor:'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('45 min'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('45 min'), findsOneWidget);

    // arrasta "Avisos Finais" (5º) para o topo
    final alcas = find.byIcon(Icons.drag_handle);
    expect(alcas, findsNWidgets(5));
    final g = await tester.startGesture(tester.getCenter(alcas.at(4)));
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 20; i++) {
      await g.moveBy(const Offset(0, -15));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    final salvo = Storage.instance.avisos.buscar(a.id)!;
    expect(salvo.tempoLouvor, '45 min');
    expect(salvo.ordem.first, 'avisosFinais');
    expect(tester.takeException(), isNull);
  });
}
