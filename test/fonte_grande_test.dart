import 'package:avisos/models/anotacao.dart';
import 'package:avisos/models/aviso.dart';
import 'package:avisos/screens/anotacao_screen.dart';
import 'package:avisos/screens/anotacoes_screen.dart';
import 'package:avisos/screens/departamentos_screen.dart';
import 'package:avisos/screens/escala_screen.dart';
import 'package:avisos/screens/escalas_screen.dart';
import 'package:avisos/screens/form_screen.dart';
import 'package:avisos/screens/history_screen.dart';
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
    await Storage.instance.avisos.salvar(
      Aviso.novo()
        ..culto = 'Culto de Celebração da Família'
        ..data = DateTime(2026, 10, 4),
    );
    await Storage.instance.anotacoes.salvar(
      Anotacao.nova()
        ..titulo = 'Reunião de líderes do trimestre'
        ..corpo = 'Texto ' * 50,
    );
  });

  final telas = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'form': () => const FormScreen(),
    'historico': () => const HistoryScreen(),
    'anotacao': () => const AnotacaoScreen(),
    'anotacoes': () => const AnotacoesScreen(),
    'departamentos': () => const DepartamentosScreen(),
    'escalas': () => const EscalasScreen(),
    'escala': () => EscalaScreen(
      departamento: Storage.instance.departamentos.buscar('padrao_louvor')!
        ..pessoas = ['Junior Albuquerque', 'Maria', 'Carlos'],
      ano: 2026,
      mes: 10,
    ),
  };

  for (final escala in [1.0, 1.3]) {
    for (final e in telas.entries) {
      testWidgets('${e.key} com fonte ${escala}x', (tester) async {
        tester.view.physicalSize = const Size(1080, 2400); // 360x800
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: temaApp(),
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(
                c,
              ).copyWith(textScaler: TextScaler.linear(escala)),
              child: child!,
            ),
            home: e.value(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
