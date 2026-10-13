import 'package:avisos/models/aviso.dart';
import 'package:avisos/screens/form_screen.dart';
import 'package:avisos/services/storage.dart';
import 'package:avisos/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
    await Storage.instance.init();
  });

  Future<void> abrirEVoltar(
    WidgetTester tester,
    Aviso a, {
    String? digitar,
  }) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: nav, theme: temaApp(), home: const Scaffold()),
    );
    nav.currentState!.push(
      MaterialPageRoute(builder: (_) => FormScreen(aviso: a)),
    );
    await tester.pumpAndSettle();
    if (digitar != null) {
      await tester.enterText(find.byType(TextField).first, digitar);
    }
    nav.currentState!.maybePop();
    await tester.pumpAndSettle();
  }

  testWidgets('abrir e voltar sem mexer não altera a data', (tester) async {
    final antigo = DateTime(2026, 1, 1);
    final a = Aviso.novo()
      ..culto = 'Culto'
      ..atualizadoEm = antigo;
    await Storage.instance.avisos.salvar(a);
    await abrirEVoltar(tester, a);
    expect(Storage.instance.avisos.buscar(a.id)!.atualizadoEm, antigo);
  });

  testWidgets('editar e voltar salva', (tester) async {
    final a = Aviso.novo()
      ..culto = 'Culto'
      ..atualizadoEm = DateTime(2026, 1, 1);
    await Storage.instance.avisos.salvar(a);
    await abrirEVoltar(tester, a, digitar: 'Culto de Domingo');
    final salvo = Storage.instance.avisos.buscar(a.id)!;
    expect(salvo.culto, 'Culto de Domingo');
    expect(salvo.atualizadoEm.year, DateTime.now().year);
  });

  testWidgets('usar como modelo e voltar sem mexer não cria cópia', (
    tester,
  ) async {
    final a = Aviso.novo()..culto = 'Culto';
    await Storage.instance.avisos.salvar(a);
    await abrirEVoltar(tester, a.duplicar());
    expect(Storage.instance.avisos.todos().length, 1);
  });
}
