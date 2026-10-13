import 'package:flutter/material.dart';

import '../models/anotacao.dart';
import '../models/aviso.dart';
import '../models/escala.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/logo.dart';
import 'anotacao_screen.dart';
import 'anotacoes_screen.dart';
import 'departamentos_screen.dart';
import 'escala_screen.dart';
import 'escalas_screen.dart';
import 'form_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Avisos, anotações e escalas misturados, mais recentes primeiro.
  List<Object> _recentes = [];

  @override
  void initState() {
    super.initState();
    _recarregar();
  }

  void _recarregar() {
    final s = Storage.instance;
    final itens = <(DateTime, Object)>[
      for (final a in s.avisos.todos().take(3)) (a.atualizadoEm, a),
      for (final n in s.anotacoes.todos().take(3)) (n.atualizadoEm, n),
      for (final e in s.escalas.todos().take(3)) (e.atualizadoEm, e),
    ]..sort((x, y) => y.$1.compareTo(x.$1));
    setState(() => _recentes = itens.take(3).map((e) => e.$2).toList());
  }

  Future<void> _abrir(Widget tela) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return FundoFuturista(
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            children: [
              const Center(child: Logo(altura: 130)),
              const SizedBox(height: 18),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'VERBO MALVINAS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Cores.texto,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'IGREJA VERBO DA VIDA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Cores.ciano,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 36),
              BotaoNeon(
                onTap: () => _abrir(const FormScreen()),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: const _ConteudoBotao(
                  icone: Icons.campaign_outlined,
                  titulo: 'GERAR AVISOS',
                  subtitulo: 'Preencher um novo informativo',
                ),
              ),
              const SizedBox(height: 14),
              BotaoNeon(
                onTap: () => _abrir(const AnotacaoScreen()),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: const _ConteudoBotao(
                  icone: Icons.edit_note_rounded,
                  titulo: 'GERAR ANOTAÇÕES',
                  subtitulo: 'Escrever um texto livre em PDF',
                ),
              ),
              const SizedBox(height: 14),
              BotaoNeon(
                onTap: () => _abrir(const DepartamentosScreen()),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: const _ConteudoBotao(
                  icone: Icons.calendar_month_outlined,
                  titulo: 'GERAR ESCALA',
                  subtitulo: 'Escala do mês por departamento',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Atalho(
                      icone: Icons.history_rounded,
                      titulo: 'Avisos',
                      onTap: () => _abrir(const HistoryScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Atalho(
                      icone: Icons.sticky_note_2_outlined,
                      titulo: 'Anotações',
                      onTap: () => _abrir(const AnotacoesScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Atalho(
                      icone: Icons.event_note_outlined,
                      titulo: 'Escalas',
                      onTap: () => _abrir(const EscalasScreen()),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Salvos',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Cores.textoSuave, fontSize: 11.5),
                ),
              ),
              if (_recentes.isNotEmpty) ...[
                const SizedBox(height: 24),
                const TituloSecao('Recentes'),
                for (final r in _recentes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: switch (r) {
                      Aviso a => AvisoCard(
                        aviso: a,
                        onTap: () => _abrir(FormScreen(aviso: a)),
                      ),
                      Anotacao n => AnotacaoCard(
                        anotacao: n,
                        onTap: () => _abrir(AnotacaoScreen(anotacao: n)),
                      ),
                      Escala e => EscalaCard(
                        escala: e,
                        onTap: () => _abrir(
                          EscalaScreen(
                            departamento: departamentoDa(e),
                            ano: e.ano,
                            mes: e.mes,
                          ),
                        ),
                      ),
                      _ => const SizedBox(),
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConteudoBotao extends StatelessWidget {
  const _ConteudoBotao({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
  });

  final IconData icone;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icone, size: 30, color: Colors.white),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: TextStyle(
                  color: Color(0xDDFFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: Colors.white,
        ),
      ],
    );
  }
}

/// Cartão de vidro compacto para as listas salvas.
class _Atalho extends StatelessWidget {
  const _Atalho({
    required this.icone,
    required this.titulo,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Vidro(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icone, color: Cores.ciano, size: 28),
          const SizedBox(height: 10),
          Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              color: Cores.texto,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
