import 'package:flutter/material.dart';

import '../models/departamento.dart';
import '../services/storage.dart';
import '../theme.dart';
import 'escala_screen.dart';
import 'escalas_screen.dart';

/// Primeira tela do módulo de escala: escolher o departamento.
class DepartamentosScreen extends StatefulWidget {
  const DepartamentosScreen({super.key});

  @override
  State<DepartamentosScreen> createState() => _DepartamentosScreenState();
}

class _DepartamentosScreenState extends State<DepartamentosScreen> {
  List<Departamento> _lista = Storage.instance.listaDepartamentos();

  void _recarregar() =>
      setState(() => _lista = Storage.instance.listaDepartamentos());

  Future<void> _abrir(Widget tela) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
    _recarregar();
  }

  Future<void> _criar() async {
    final r = await editarDepartamento(context);
    if (r == null) return;
    final d = Departamento.novo(r.nome, icone: r.icone);
    await Storage.instance.departamentos.salvar(d);
    _recarregar();
  }

  Future<void> _opcoes(Departamento d) async {
    final acao = await opcoesDepartamento(context, d);
    if (!mounted) return;
    if (acao == 'editar') {
      if (await editarESalvarDepartamento(context, d)) _recarregar();
    } else if (acao == 'excluir') {
      if (await excluirDepartamento(context, d)) _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FundoFuturista(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ESCALA'),
          actions: [
            IconButton(
              tooltip: 'Escalas salvas',
              icon: const Icon(Icons.history_rounded),
              onPressed: () => _abrir(const EscalasScreen()),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Escolha o departamento',
                style: TextStyle(color: Cores.textoSuave, fontSize: 14),
              ),
            ),
            const TituloSecao('Departamentos'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              // cartões mais altos quando a fonte do celular está aumentada
              childAspectRatio: 1.1 / MediaQuery.textScalerOf(context).scale(1),
              children: [
                for (final d in _lista)
                  _CartaoDepartamento(
                    departamento: d,
                    onTap: () => _abrir(EscalaScreen(departamento: d)),
                    onOpcoes: () => _opcoes(d),
                  ),
                _CartaoNovo(onTap: _criar),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Toque em ⋮ para editar ou excluir um departamento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Cores.textoSuave, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoDepartamento extends StatelessWidget {
  const _CartaoDepartamento({
    required this.departamento,
    required this.onTap,
    required this.onOpcoes,
  });

  final Departamento departamento;
  final VoidCallback onTap;
  final VoidCallback onOpcoes;

  @override
  Widget build(BuildContext context) {
    final n = departamento.pessoas.length;
    return Vidro(
      onTap: onTap,
      onLongPress: onOpcoes,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: Cores.gradienteAcao,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Cores.azul.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  departamento.iconData,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Editar ou excluir',
                visualDensity: VisualDensity.compact,
                onPressed: onOpcoes,
                icon: const Icon(Icons.more_vert, color: Cores.textoSuave),
              ),
            ],
          ),
          const Spacer(),
          Text(
            departamento.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Cores.texto,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Text(
            n == 0 ? 'Sem pessoas' : '$n pessoa${n == 1 ? '' : 's'}',
            style: const TextStyle(color: Cores.textoSuave, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CartaoNovo extends StatelessWidget {
  const _CartaoNovo({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Cores.ciano.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: Cores.ciano, size: 32),
              SizedBox(height: 8),
              Text(
                'Novo\ndepartamento',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Cores.ciano,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo de criar/editar departamento: nome + ícone.
Future<({String nome, String icone})?> editarDepartamento(
  BuildContext context, {
  Departamento? atual,
}) {
  final nome = TextEditingController(text: atual?.nome ?? '');
  var icone = atual?.icone ?? 'grupo';
  return showDialog<({String nome, String icone})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) {
        void ok() {
          if (nome.text.trim().isEmpty) return;
          Navigator.pop(ctx, (nome: nome.text.trim(), icone: icone));
        }

        return AlertDialog(
          title: Text(atual == null ? 'Novo departamento' : 'Editar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nome,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome'),
                onSubmitted: (_) => ok(),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in iconesDepartamento.entries)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setD(() => icone = e.key),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: icone == e.key ? Cores.gradienteAcao : null,
                          border: Border.all(color: Cores.vidroBorda),
                        ),
                        child: Icon(e.value, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(onPressed: ok, child: const Text('Salvar')),
          ],
        );
      },
    ),
  );
}

/// Menu com as opções de um departamento. Devolve 'editar', 'excluir' ou null.
Future<String?> opcoesDepartamento(BuildContext context, Departamento d) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Icon(d.iconData, color: Cores.ciano),
                const SizedBox(width: 10),
                Text(
                  d.nome,
                  style: const TextStyle(
                    color: Cores.texto,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar departamento'),
            subtitle: const Text('Nome e ícone'),
            onTap: () => Navigator.pop(ctx, 'editar'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text(
              'Excluir departamento',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () => Navigator.pop(ctx, 'excluir'),
          ),
        ],
      ),
    ),
  );
}

/// Abre o diálogo de edição e salva. Devolve true se mudou algo.
Future<bool> editarESalvarDepartamento(
  BuildContext context,
  Departamento d,
) async {
  final r = await editarDepartamento(context, atual: d);
  if (r == null) return false;
  d
    ..nome = r.nome
    ..icone = r.icone;
  await Storage.instance.departamentos.salvar(d);
  // mantém o nome atualizado nas escalas já salvas
  final escalas = Storage.instance.escalas
      .todos()
      .where((e) => e.departamentoId == d.id)
      .toList();
  for (final e in escalas) {
    e.departamentoNome = d.nome;
  }
  if (escalas.isNotEmpty) {
    await Storage.instance.escalas.salvarVarios(escalas);
  }
  return true;
}

/// Pergunta e exclui o departamento (e, se escolhido, as escalas dele).
/// Devolve true se excluiu.
Future<bool> excluirDepartamento(BuildContext context, Departamento d) async {
  final escalas = Storage.instance.escalas
      .todos()
      .where((e) => e.departamentoId == d.id)
      .toList();
  var apagarEscalas = false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: Text('Excluir "${d.nome}"?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.pessoas.isEmpty
                  ? 'O departamento será removido.'
                  : 'O departamento e a lista de ${d.pessoas.length} '
                        'pessoa(s) serão removidos.',
            ),
            if (escalas.isNotEmpty) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: apagarEscalas,
                onChanged: (v) => setD(() => apagarEscalas = v ?? false),
                title: Text(
                  'Apagar também ${escalas.length} escala(s) salva(s)',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Excluir'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return false;

  await Storage.instance.departamentos.excluir(d.id);
  if (apagarEscalas) {
    for (final e in escalas) {
      await Storage.instance.escalas.excluir(e.id);
    }
  }
  return true;
}

Future<bool> confirmar(BuildContext context, String titulo, String acao) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(acao),
        ),
      ],
    ),
  );
  return r == true;
}
