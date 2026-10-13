import 'package:avisos/models/escala.dart';
import 'package:avisos/screens/departamentos_screen.dart';
import 'package:avisos/screens/escala_screen.dart';
import 'package:avisos/screens/home_screen.dart';
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

  void celular(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400); // 360x800
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Widget app(Widget home) => MaterialApp(theme: temaApp(), home: home);

  testWidgets('calendário cheio não transborda', (tester) async {
    celular(tester);
    final dep = Storage.instance.departamentos.buscar('padrao_louvor')!
      ..pessoas = ['Junior Albuquerque', 'Maria', 'Carlos', 'Ana Paula'];
    await Storage.instance.escalas.salvar(
      Escala(
        departamentoId: dep.id,
        departamentoNome: dep.nome,
        ano: 2026,
        mes: 10,
        dias: [
          for (var d = 1; d <= 31; d++)
            DiaEscala(dia: d, pessoas: [...dep.pessoas], obs: 'Culto'),
        ],
      ),
    );
    await tester.pumpWidget(
      app(EscalaScreen(departamento: dep, ano: 2026, mes: 10)),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('painel e departamentos não transbordam', (tester) async {
    celular(tester);
    await tester.pumpWidget(app(const HomeScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(app(const DepartamentosScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
