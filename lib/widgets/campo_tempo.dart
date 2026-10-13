import 'package:flutter/material.dart';

import '../models/aviso.dart';
import '../theme.dart';

/// Campo de tempo (duração). Não aceita digitação livre: ao tocar abre um
/// seletor de minutos, e o valor fica sempre no formato "30 min" / "1h 15min".
class CampoTempo extends StatelessWidget {
  const CampoTempo({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.onChanged,
  });

  final String rotulo;

  /// Texto salvo ("30 min") ou vazio.
  final String valor;
  final ValueChanged<String> onChanged;

  Future<void> _abrir(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final r = await escolherTempo(context, rotulo, minutosDe(valor));
    if (r == null) return; // cancelou
    onChanged(r == 0 ? '' : formatarTempo(r));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrir(context),
        child: InputDecorator(
          isEmpty: valor.isEmpty,
          decoration: InputDecoration(
            labelText: rotulo,
            suffixIcon: const Icon(Icons.timer_outlined, size: 20),
          ),
          child: Text(valor, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

const _rapidos = [5, 10, 15, 20, 25, 30, 40, 45, 60, 90];

/// Abre o seletor. Devolve os minutos, 0 para "sem tempo" ou null se cancelou.
Future<int?> escolherTempo(BuildContext context, String titulo, int? atual) {
  var minutos = atual ?? 30;
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        void somar(int d) =>
            setS(() => minutos = (minutos + d).clamp(1, 600).toInt());

        Widget passo(String texto, int d) => SizedBox(
          width: 56,
          height: 44,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: Cores.ciano,
              side: const BorderSide(color: Cores.vidroBorda),
            ),
            onPressed: () => somar(d),
            child: Text(texto),
          ),
        );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo.replaceAll(':', ''),
                  style: const TextStyle(color: Cores.textoSuave),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    passo('-5', -5),
                    const SizedBox(width: 6),
                    passo('-1', -1),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatarTempo(minutos),
                          style: const TextStyle(
                            color: Cores.texto,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    passo('+1', 1),
                    const SizedBox(width: 6),
                    passo('+5', 5),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final m in _rapidos)
                      ChoiceChip(
                        label: Text(formatarTempo(m)),
                        selected: minutos == m,
                        onSelected: (_) => setS(() => minutos = m),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(ctx, 0),
                      icon: const Icon(Icons.clear),
                      label: const Text('Sem tempo'),
                    ),
                    const Spacer(),
                    BotaoNeon(
                      onTap: () => Navigator.pop(ctx, minutos),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
