import 'package:avisos/models/escala.dart';
import 'package:avisos/screens/departamentos_screen.dart';
import 'package:avisos/services/storage.dart';
import 'package:avisos/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('edita e exclui departamento pelo botão ⋮', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
    final s = Storage.instance;
    await s.init();
    await s.escalas.salvar(
      Escala(
        departamentoId: 'padrao_diaconato',
        departamentoNome: 'Diaconato',
        ano: 2026,
        mes: 10,
        dias: [
          DiaEscala(dia: 4, pessoas: ['Junior']),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(theme: temaApp(), home: const DepartamentosScreen()),
    );

    // excluir Diaconato (1º cartão) junto com a escala dele
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir departamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(s.departamentos.buscar('padrao_diaconato'), isNull);
    expect(s.escalas.todos(), isEmpty);
    expect(find.text('Diaconato'), findsNothing);

    // editar DI (agora o 1º cartão) -> "Infantil"
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar departamento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Infantil');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(s.departamentos.buscar('padrao_infantil')!.nome, 'Infantil');
    expect(find.text('Infantil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
