import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/departamento.dart';
import '../models/escala.dart';
import '../services/escala_pdf.dart';
import '../services/storage.dart';
import '../theme.dart';
import 'departamentos_screen.dart'
    show confirmar, editarESalvarDepartamento, excluirDepartamento;
import 'preview_screen.dart';

const _letrasSemana = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
const _nomesSemana = [
  'domingos',
  'segundas',
  'terças',
  'quartas',
  'quintas',
  'sextas',
  'sábados',
];

/// Monta a escala de um departamento em um mês.
///
/// Jeito rápido: toque numa pessoa (ela fica "selecionada") e depois nos dias
/// em que ela serve. Sem pessoa selecionada, tocar num dia abre os detalhes
/// daquele dia.
class EscalaScreen extends StatefulWidget {
  const EscalaScreen({
    super.key,
    required this.departamento,
    this.ano,
    this.mes,
  });

  final Departamento departamento;
  final int? ano;
  final int? mes;

  @override
  State<EscalaScreen> createState() => _EscalaScreenState();
}

class _EscalaScreenState extends State<EscalaScreen> {
  late final Departamento _dep = widget.departamento;
  late int _ano = widget.ano ?? DateTime.now().year;
  late int _mes = widget.mes ?? DateTime.now().month;
  late Escala _escala = _carregar();
  String? _pincel;
  bool _ocupado = false;

  Escala _carregar() =>
      Storage.instance.escalas.buscar(Escala.idPara(_dep.id, _ano, _mes)) ??
      Escala(
        departamentoId: _dep.id,
        departamentoNome: _dep.nome,
        ano: _ano,
        mes: _mes,
      );

  void _mudarMes(int delta) {
    final d = DateTime(_ano, _mes + delta);
    setState(() {
      _ano = d.year;
      _mes = d.month;
      _escala = _carregar();
    });
  }

  Future<void> _salvar() async {
    _escala.departamentoNome = _dep.nome;
    _escala.dias.removeWhere((d) => d.pessoas.isEmpty && d.obs.trim().isEmpty);
    if (_escala.dias.isEmpty) {
      await Storage.instance.escalas.excluir(_escala.id);
      return;
    }
    _escala.atualizadoEm = DateTime.now();
    await Storage.instance.escalas.salvar(_escala);
  }

  void _alterou() {
    setState(() {});
    _salvar();
  }

  DiaEscala _diaOuNovo(int dia) {
    final existente = _escala.diaEscala(dia);
    if (existente != null) return existente;
    final novo = DiaEscala(dia: dia);
    _escala.dias.add(novo);
    return novo;
  }

  void _msg(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  // ---------- pessoas ----------

  Future<String?> _novaPessoa() async {
    final nome = await pedirNome(context);
    if (nome == null) return null;
    if (!_dep.pessoas.contains(nome)) {
      _dep.pessoas.add(nome);
      await Storage.instance.departamentos.salvar(_dep);
    }
    return nome;
  }

  Future<void> _removerPessoa(String p) async {
    final ok = await confirmar(
      context,
      'Remover "$p" do ${_dep.nome}?',
      'Remover',
    );
    if (!ok) return;
    _dep.pessoas.remove(p);
    await Storage.instance.departamentos.salvar(_dep);
    setState(() {
      if (_pincel == p) _pincel = null;
    });
  }

  // ---------- dias ----------

  void _tocarDia(int dia) {
    final p = _pincel;
    if (p == null) {
      _abrirDia(dia);
      return;
    }
    final d = _diaOuNovo(dia);
    d.pessoas.contains(p) ? d.pessoas.remove(p) : d.pessoas.add(p);
    _alterou();
  }

  /// Marca (ou desmarca) a pessoa selecionada em todos os dias daquela
  /// semana — ex.: todos os domingos.
  void _tocarSemana(int indice) {
    final p = _pincel;
    if (p == null) {
      _msg(
        'Escolha uma pessoa primeiro e depois toque em '
        '"${_letrasSemana[indice]}" para marcar todos os ${_nomesSemana[indice]}.',
      );
      return;
    }
    final total = DateUtils.getDaysInMonth(_ano, _mes);
    final dias = [
      for (var d = 1; d <= total; d++)
        if (DateTime(_ano, _mes, d).weekday % 7 == indice) d,
    ];
    final jaTodos = dias.every(
      (d) => _escala.diaEscala(d)?.pessoas.contains(p) ?? false,
    );
    for (final dia in dias) {
      final d = _diaOuNovo(dia);
      if (jaTodos) {
        d.pessoas.remove(p);
      } else if (!d.pessoas.contains(p)) {
        d.pessoas.add(p);
      }
    }
    _alterou();
    _msg(
      jaTodos
          ? '$p removido(a) dos ${_nomesSemana[indice]}'
          : '$p marcado(a) em todos os ${_nomesSemana[indice]}',
    );
  }

  Future<void> _abrirDia(int dia) async {
    final d = _diaOuNovo(dia);
    final obs = TextEditingController(text: d.obs);
    final data = _escala.data(dia);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final opcoes = {..._dep.pessoas, ...d.pessoas}.toList();
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${diaSemana(data)}, ${DateFormat('dd/MM').format(data)}',
                    style: const TextStyle(
                      color: Cores.texto,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Quem serve neste dia?',
                    style: TextStyle(color: Cores.textoSuave),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in opcoes)
                        ChipPessoa(
                          nome: p,
                          selecionado: d.pessoas.contains(p),
                          onTap: () => setS(() {
                            d.pessoas.contains(p)
                                ? d.pessoas.remove(p)
                                : d.pessoas.add(p);
                          }),
                        ),
                      ChipPessoa.adicionar(
                        onTap: () async {
                          final nome = await _novaPessoa();
                          if (nome != null && !d.pessoas.contains(nome)) {
                            setS(() => d.pessoas.add(nome));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: obs,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Observação (opcional)',
                      hintText: 'Ex.: Culto da noite',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => setS(() {
                          d.pessoas.clear();
                          obs.clear();
                        }),
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Limpar dia'),
                      ),
                      const Spacer(),
                      BotaoNeon(
                        onTap: () => Navigator.pop(ctx),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        child: const Text('PRONTO'),
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

    d.obs = obs.text;
    obs.dispose();
    _alterou();
  }

  // ---------- PDF ----------

  bool get _temAlguem => _escala.dias.any((d) => d.pessoas.isNotEmpty);

  Future<void> _enviar() async {
    if (!_temAlguem) {
      _msg('Marque pelo menos um dia antes de gerar o PDF.');
      return;
    }
    setState(() => _ocupado = true);
    try {
      await _salvar();
      await EscalaPdf.compartilhar(_escala);
    } catch (e) {
      _msg('Erro ao gerar PDF: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _visualizar() async {
    if (!_temAlguem) {
      _msg('Marque pelo menos um dia antes de gerar o PDF.');
      return;
    }
    await _salvar();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen.escala(_escala)),
    );
  }

  Future<void> _limparMes() async {
    final ok = await confirmar(
      context,
      'Limpar a escala de ${nomeMes(_ano, _mes)}?',
      'Limpar',
    );
    if (!ok) return;
    _escala.dias.clear();
    _alterou();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return FundoFuturista(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_dep.nome.toUpperCase()),
          actions: [
            IconButton(
              tooltip: 'Visualizar PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _visualizar,
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'limpar':
                    _limparMes();
                  case 'editar':
                    if (await editarESalvarDepartamento(context, _dep)) {
                      _escala.departamentoNome = _dep.nome;
                      setState(() {});
                    }
                  case 'excluir':
                    if (await excluirDepartamento(context, _dep) &&
                        context.mounted) {
                      Navigator.pop(context);
                    }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'editar',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Editar departamento'),
                  ),
                ),
                PopupMenuItem(
                  value: 'limpar',
                  child: ListTile(
                    leading: Icon(Icons.clear_all),
                    title: Text('Limpar mês'),
                  ),
                ),
                PopupMenuItem(
                  value: 'excluir',
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      'Excluir departamento',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            _seletorMes(),
            TituloSecao(
              'Pessoas',
              acao: IconButton(
                tooltip: 'Adicionar pessoa',
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  final nome = await _novaPessoa();
                  if (nome != null) setState(() => _pincel = nome);
                },
                icon: const Icon(Icons.person_add_alt, color: Cores.ciano),
              ),
            ),
            _pessoas(),
            const TituloSecao('Dias'),
            _calendario(),
            const TituloSecao('Escala do mês'),
            _tabela(),
            const SizedBox(height: 20),
            SafeArea(
              top: false,
              child: BotaoNeon(
                onTap: _ocupado ? null : _enviar,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: RotuloEnviar(ocupado: _ocupado),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seletorMes() => Vidro(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: Row(
      children: [
        IconButton(
          onPressed: () => _mudarMes(-1),
          icon: const Icon(Icons.chevron_left_rounded, color: Cores.ciano),
        ),
        Expanded(
          child: Text(
            nomeMes(_ano, _mes),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Cores.texto,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _mudarMes(1),
          icon: const Icon(Icons.chevron_right_rounded, color: Cores.ciano),
        ),
      ],
    ),
  );

  Widget _pessoas() {
    final p = _pincel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final nome in _dep.pessoas)
              ChipPessoa(
                nome: nome,
                selecionado: nome == p,
                onTap: () => setState(() => _pincel = nome == p ? null : nome),
                onLongPress: () => _removerPessoa(nome),
              ),
            ChipPessoa.adicionar(
              onTap: () async {
                final nome = await _novaPessoa();
                if (nome != null) setState(() => _pincel = nome);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              p == null ? Icons.touch_app_outlined : Icons.brush_outlined,
              size: 16,
              color: p == null ? Cores.textoSuave : Cores.ciano,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                p == null
                    ? 'Toque numa pessoa e depois nos dias em que ela serve. '
                          'Segure o nome para remover.'
                    : 'Marcando $p: toque nos dias. Toque na letra (D, S...) '
                          'para marcar o mês todo naquele dia da semana.',
                style: TextStyle(
                  color: p == null ? Cores.textoSuave : Cores.ciano,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _calendario() {
    final total = DateUtils.getDaysInMonth(_ano, _mes);
    final inicio = DateTime(_ano, _mes, 1).weekday % 7; // domingo = 0
    final hoje = DateUtils.dateOnly(DateTime.now());

    return Vidro(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _tocarSemana(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _letrasSemana[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: i == 0 ? Cores.ciano : Cores.textoSuave,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 0.64,
            ),
            itemCount: inicio + total,
            itemBuilder: (_, i) {
              if (i < inicio) return const SizedBox();
              final dia = i - inicio + 1;
              final pessoas = _escala.diaEscala(dia)?.pessoas ?? const [];
              return _CelulaDia(
                dia: dia,
                pessoas: pessoas,
                destacado: _pincel != null && pessoas.contains(_pincel),
                domingo: (inicio + dia - 1) % 7 == 0,
                hoje: _escala.data(dia) == hoje,
                onTap: () => _tocarDia(dia),
                onLongPress: () => _abrirDia(dia),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tabela() {
    final dias = _escala.ordenados.where((d) => d.pessoas.isNotEmpty).toList();
    if (dias.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Nenhum dia marcado ainda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Cores.textoSuave),
        ),
      );
    }
    return Vidro(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < dias.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Cores.vidroBorda),
            InkWell(
              onTap: () => _abrirDia(dias[i].dia),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(
                              'dd/MM',
                            ).format(_escala.data(dias[i].dia)),
                            style: const TextStyle(
                              color: Cores.texto,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'EEE',
                              'pt_BR',
                            ).format(_escala.data(dias[i].dia)),
                            style: const TextStyle(
                              color: Cores.ciano,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dias[i].pessoas.join(', '),
                            style: const TextStyle(color: Cores.texto),
                          ),
                          if (dias[i].obs.trim().isNotEmpty)
                            Text(
                              dias[i].obs.trim(),
                              style: const TextStyle(
                                color: Cores.textoSuave,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Cores.textoSuave,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CelulaDia extends StatelessWidget {
  const _CelulaDia({
    required this.dia,
    required this.pessoas,
    required this.destacado,
    required this.domingo,
    required this.hoje,
    required this.onTap,
    required this.onLongPress,
  });

  final int dia;
  final List<String> pessoas;
  final bool destacado;
  final bool domingo;
  final bool hoje;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final preenchido = pessoas.isNotEmpty;
    final r = BorderRadius.circular(10);
    final primeiros = pessoas.map((p) => p.split(' ').first).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: preenchido
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Cores.azul.withValues(alpha: destacado ? 0.75 : 0.35),
                  Cores.ciano.withValues(alpha: destacado ? 0.45 : 0.15),
                ],
              )
            : null,
        color: preenchido ? null : const Color(0x08FFFFFF),
        border: Border.all(
          color: destacado
              ? Cores.ciano
              : hoje
              ? Cores.ciano.withValues(alpha: 0.5)
              : Cores.vidroBorda,
          width: destacado ? 1.5 : 1,
        ),
        boxShadow: destacado
            ? [
                BoxShadow(
                  color: Cores.ciano.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 5, 3, 3),
            // rolagem travada: se não couber (fonte grande), corta em vez de quebrar
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  Text(
                    '$dia',
                    style: TextStyle(
                      color: domingo ? Cores.ciano : Cores.texto,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  for (final nome in primeiros.take(2))
                    Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        height: 1.25,
                      ),
                    ),
                  if (primeiros.length > 2)
                    Text(
                      '+${primeiros.length - 2}',
                      style: const TextStyle(
                        color: Cores.ciano,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta com o nome de uma pessoa; brilha quando selecionada.
class ChipPessoa extends StatelessWidget {
  const ChipPessoa({
    super.key,
    required this.nome,
    required this.selecionado,
    required this.onTap,
    this.onLongPress,
  }) : _adicionar = false;

  const ChipPessoa.adicionar({super.key, required this.onTap})
    : nome = 'Pessoa',
      selecionado = false,
      onLongPress = null,
      _adicionar = true;

  final String nome;
  final bool selecionado;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool _adicionar;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(30);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: selecionado ? Cores.gradienteAcao : null,
        color: selecionado ? null : const Color(0x0DFFFFFF),
        border: Border.all(
          color: _adicionar
              ? Cores.ciano.withValues(alpha: 0.6)
              : selecionado
              ? Colors.transparent
              : Cores.vidroBorda,
        ),
        boxShadow: selecionado
            ? [
                BoxShadow(
                  color: Cores.azul.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_adicionar || selecionado) ...[
                  Icon(
                    _adicionar ? Icons.add : Icons.check,
                    size: 16,
                    color: _adicionar ? Cores.ciano : Colors.white,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _adicionar ? Cores.ciano : Colors.white,
                      fontWeight: selecionado
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pede o nome de uma pessoa nova.
Future<String?> pedirNome(BuildContext context) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      void ok() {
        final nome = c.text.trim();
        if (nome.isNotEmpty) Navigator.pop(ctx, nome);
      }

      return AlertDialog(
        title: const Text('Nova pessoa'),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome'),
          onSubmitted: (_) => ok(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(onPressed: ok, child: const Text('Adicionar')),
        ],
      );
    },
  );
}
