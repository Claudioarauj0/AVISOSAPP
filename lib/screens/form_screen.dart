import 'package:flutter/material.dart';

import '../models/aviso.dart';
import '../services/pdf_service.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/campo_tempo.dart';
import '../widgets/logo.dart';
import 'preview_screen.dart';

/// Um campo de uma lista arrastável. O id fixo permite que o Flutter
/// acompanhe o item enquanto ele muda de posição.
class _Item {
  static int _seq = 0;
  final int id = _seq++;
  final TextEditingController c;
  _Item(String texto) : c = TextEditingController(text: texto);
}

const _iconesSecao = {
  'louvor': Icons.music_note_outlined,
  'direcao': Icons.mic_none_outlined,
  'avisos': Icons.campaign_outlined,
  'ministracao': Icons.menu_book_outlined,
  'avisosFinais': Icons.flag_outlined,
};

class FormScreen extends StatefulWidget {
  const FormScreen({super.key, this.aviso});

  /// Nulo = novo aviso.
  final Aviso? aviso;

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  /// Aviso novo já vem com a ordem de seções do último aviso usado.
  late final Aviso _aviso =
      widget.aviso ??
      (Aviso.novo()
        ..ordem = [
          ...(Storage.instance.avisos.todos().firstOrNull?.ordem ??
              secoesPadrao),
        ]);

  late final _culto = TextEditingController(text: _aviso.culto);
  late final _ministroLouvor = TextEditingController(
    text: _aviso.ministroLouvor,
  );
  late final _dirigente = TextEditingController(text: _aviso.dirigente);
  late final _ministro = TextEditingController(text: _aviso.ministro);
  late DateTime? _data = _aviso.data;

  // tempos: só mudam pelo seletor, sempre no formato "30 min"
  late String _tempoLouvor = _aviso.tempoLouvor;
  late String _tempoDirecao = _aviso.tempoDirecao;
  late String _tempoMinistracao = _aviso.tempoMinistracao;

  late final List<String> _ordem = [..._aviso.ordem];

  late final List<_Item> _musicas = _aviso.musicas.map(_Item.new).toList();
  late final List<_Item> _avisos = _aviso.avisos.map(_Item.new).toList();
  late final List<_Item> _avisosFinais = _aviso.avisosFinais
      .map(_Item.new)
      .toList();

  bool _ocupado = false;
  late String _salvo;

  @override
  void initState() {
    super.initState();
    _salvo = _conteudo(_aviso);
  }

  @override
  void dispose() {
    for (final c in [
      _culto,
      _ministroLouvor,
      _dirigente,
      _ministro,
      ..._musicas.map((i) => i.c),
      ..._avisos.map((i) => i.c),
      ..._avisosFinais.map((i) => i.c),
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Aviso _coletar() {
    List<String> textos(List<_Item> l) => l.map((i) => i.c.text).toList();
    return _aviso
      ..culto = _culto.text
      ..data = _data
      ..tempoLouvor = _tempoLouvor
      ..ministroLouvor = _ministroLouvor.text
      ..musicas = textos(_musicas)
      ..tempoDirecao = _tempoDirecao
      ..dirigente = _dirigente.text
      ..avisos = textos(_avisos)
      ..tempoMinistracao = _tempoMinistracao
      ..ministro = _ministro.text
      ..avisosFinais = textos(_avisosFinais)
      ..ordem = [..._ordem];
  }

  /// Conteúdo do aviso sem as datas de controle, para saber se algo mudou.
  String _conteudo(Aviso a) {
    final j = a.toJson()
      ..remove('criadoEm')
      ..remove('atualizadoEm');
    return j.toString();
  }

  bool get _jaGuardado => Storage.instance.avisos.buscar(_aviso.id) != null;

  /// Salva só quando algo mudou (ou quando o usuário pede e o aviso ainda não
  /// existe, como uma cópia de "usar como modelo"). Assim abrir e voltar não
  /// muda a ordem da lista nem cria cópias sem querer.
  Future<void> _salvar({bool mostrarMsg = true, bool forcar = false}) async {
    final a = _coletar();
    if (a.vazio) return;
    final mudou = _conteudo(a) != _salvo;
    if (!mudou && (_jaGuardado || !forcar)) {
      if (mostrarMsg && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nada novo para salvar')));
      }
      return;
    }
    a.atualizadoEm = DateTime.now();
    _salvo = _conteudo(a);
    await Storage.instance.avisos.salvar(a);
    if (mostrarMsg && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aviso salvo')));
    }
  }

  Future<void> _enviar() async {
    setState(() => _ocupado = true);
    try {
      await _salvar(mostrarMsg: false, forcar: true);
      await PdfService.compartilhar(_aviso);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _visualizar() async {
    await _salvar(mostrarMsg: false, forcar: true);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen.aviso(_aviso)),
    );
  }

  Future<void> _escolherData() async {
    FocusScope.of(context).unfocus();
    final hoje = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _data ?? hoje,
      firstDate: DateTime(hoje.year - 5),
      lastDate: DateTime(hoje.year + 5),
    );
    if (d != null) setState(() => _data = d);
  }

  // ---------- widgets ----------

  Widget _campo(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: c,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: label),
    ),
  );

  /// Cabeçalho de uma lista arrastável, com botão para adicionar item.
  Widget _secaoLista(String titulo, List<_Item> lista) => TituloSecao(
    titulo,
    acao: IconButton(
      tooltip: 'Adicionar',
      visualDensity: VisualDensity.compact,
      onPressed: () => setState(() => lista.add(_Item(''))),
      icon: const Icon(Icons.add_circle_outline, color: Cores.ciano),
    ),
  );

  /// Item "flutuando" enquanto é arrastado.
  Widget _flutuando(Widget child, int _, Animation<double> _) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Cores.ciano.withValues(alpha: 0.35), blurRadius: 20),
      ],
    ),
    child: Material(color: Colors.transparent, child: child),
  );

  /// Lista em que cada campo pode ser arrastado pela alça para trocar de
  /// posição com os outros.
  Widget _listaArrastavel(List<_Item> lista, String Function(int) rotulo) {
    return SliverReorderableList(
      itemCount: lista.length,
      onReorder: (de, para) => setState(() {
        if (para > de) para--;
        lista.insert(para, lista.removeAt(de));
      }),
      proxyDecorator: _flutuando,
      itemBuilder: (context, i) {
        final item = lista[i];
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: i,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(0, 12, 8, 12),
                  child: Icon(Icons.drag_indicator, color: Cores.ciano),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: item.c,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: rotulo(i),
                    suffixIcon: IconButton(
                      tooltip: 'Remover',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        lista.remove(item);
                        // descarta depois do frame para não quebrar o campo
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => item.c.dispose(),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Cartão "Ordem do culto": arrastar as seções muda a ordem delas no
  /// formulário e no PDF.
  Widget _ordemDoCulto() {
    return Vidro(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        proxyDecorator: _flutuando,
        onReorder: (de, para) => setState(() {
          if (para > de) para--;
          _ordem.insert(para, _ordem.removeAt(de));
        }),
        children: [
          for (var i = 0; i < _ordem.length; i++)
            ReorderableDelayedDragStartListener(
              key: ValueKey(_ordem[i]),
              index: i,
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: Cores.azul.withValues(alpha: 0.35),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Icon(_iconesSecao[_ordem[i]], size: 18, color: Cores.ciano),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        nomesSecao[_ordem[i]]!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Cores.texto,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: ReorderableDragStartListener(
                  index: i,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle, color: Cores.ciano),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _secaoFixa(List<Widget> filhos) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    sliver: SliverList.list(children: filhos),
  );

  Widget _secaoItens(List<_Item> lista, String Function(int) rotulo) =>
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: _listaArrastavel(lista, rotulo),
      );

  /// Os pedaços (slivers) de cada seção, na ordem escolhida.
  List<Widget> _secao(String chave) => switch (chave) {
    'louvor' => [
      _secaoFixa([
        const TituloSecao('Louvor'),
        CampoTempo(
          rotulo: 'Tempo de louvor:',
          valor: _tempoLouvor,
          onChanged: (v) => setState(() => _tempoLouvor = v),
        ),
        _campo(_ministroLouvor, 'Ministro de louvor:'),
        _secaoLista('Músicas', _musicas),
      ]),
      _secaoItens(_musicas, (i) => 'Música ${i + 1}'),
    ],
    'direcao' => [
      _secaoFixa([
        const TituloSecao('Direção'),
        CampoTempo(
          rotulo: 'Tempo de direção:',
          valor: _tempoDirecao,
          onChanged: (v) => setState(() => _tempoDirecao = v),
        ),
        _campo(_dirigente, 'Dirigente:'),
      ]),
    ],
    'avisos' => [
      _secaoFixa([_secaoLista('Avisos', _avisos)]),
      _secaoItens(_avisos, (i) => 'Aviso ${i + 1}'),
    ],
    'ministracao' => [
      _secaoFixa([
        const TituloSecao('Ministração'),
        CampoTempo(
          rotulo: 'Tempo de ministração:',
          valor: _tempoMinistracao,
          onChanged: (v) => setState(() => _tempoMinistracao = v),
        ),
        _campo(_ministro, 'Nome do Ministro:'),
      ]),
    ],
    'avisosFinais' => [
      _secaoFixa([_secaoLista('Avisos Finais', _avisosFinais)]),
      _secaoItens(_avisosFinais, (i) => 'Aviso final ${i + 1}'),
    ],
    _ => const [],
  };

  @override
  Widget build(BuildContext context) {
    final novo = widget.aviso == null || !_jaGuardado;
    return PopScope(
      // salva automaticamente ao voltar
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _salvar(mostrarMsg: false);
      },
      child: FundoFuturista(
        child: Scaffold(
          appBar: AppBar(
            title: Text(novo ? 'NOVO AVISO' : 'EDITAR AVISO'),
            actions: [
              IconButton(
                tooltip: 'Salvar',
                icon: const Icon(Icons.save_outlined),
                onPressed: () => _salvar(forcar: true),
              ),
              IconButton(
                tooltip: 'Visualizar PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: _visualizar,
              ),
            ],
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverList.list(
                    children: [
                      const Center(child: Logo(altura: 80)),
                      const SizedBox(height: 24),
                      _campo(_culto, 'Culto'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: InkWell(
                          onTap: _escolherData,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Data',
                              suffixIcon: Icon(Icons.calendar_today, size: 20),
                            ),
                            isEmpty: _data == null,
                            child: Text(
                              formatarData(_data),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      const TituloSecao('Ordem do culto'),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Arraste pela alça (≡) para mudar a ordem das '
                          'seções no formulário e no PDF.',
                          style: TextStyle(
                            color: Cores.textoSuave,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      _ordemDoCulto(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                for (final chave in _ordem) ..._secao(chave),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                  sliver: SliverToBoxAdapter(
                    child: SafeArea(
                      top: false,
                      child: BotaoNeon(
                        onTap: _ocupado ? null : _enviar,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: RotuloEnviar(ocupado: _ocupado),
                      ),
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
