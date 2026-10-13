import 'package:flutter/material.dart';

import '../models/anotacao.dart';
import '../services/anotacao_pdf.dart';
import '../services/storage.dart';
import '../theme.dart';
import 'anotacao_screen.dart';
import 'preview_screen.dart';

class AnotacoesScreen extends StatefulWidget {
  const AnotacoesScreen({super.key});

  @override
  State<AnotacoesScreen> createState() => _AnotacoesScreenState();
}

class _AnotacoesScreenState extends State<AnotacoesScreen> {
  List<Anotacao> _lista = Storage.instance.anotacoes.todos();

  void _recarregar() =>
      setState(() => _lista = Storage.instance.anotacoes.todos());

  Future<void> _abrir(Widget tela) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
    _recarregar();
  }

  Future<void> _excluir(Anotacao n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir anotação?'),
        content: Text(n.tituloOuPadrao),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Storage.instance.anotacoes.excluir(n.id);
      _recarregar();
    }
  }

  void _opcoes(Anotacao n) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        void acao(VoidCallback f) {
          Navigator.pop(ctx);
          f();
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () => acao(() => _abrir(AnotacaoScreen(anotacao: n))),
              ),
              ListTile(
                leading: const Icon(Icons.send),
                title: const Text('Enviar PDF (WhatsApp)'),
                onTap: () => acao(() => AnotacaoPdf.compartilhar(n)),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Visualizar PDF'),
                onTap: () => acao(() => _abrir(PreviewScreen.anotacao(n))),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () => acao(() => _excluir(n)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FundoFuturista(
      child: Scaffold(
        appBar: AppBar(title: const Text('ANOTAÇÕES')),
        floatingActionButton: BotaoNeon(
          onTap: () => _abrir(const AnotacaoScreen()),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.add), SizedBox(width: 8), Text('NOVA')],
          ),
        ),
        body: _lista.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 56,
                      color: Cores.textoSuave,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nenhuma anotação ainda.',
                      style: TextStyle(color: Cores.textoSuave),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: _lista.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => AnotacaoCard(
                  anotacao: _lista[i],
                  onTap: () => _abrir(AnotacaoScreen(anotacao: _lista[i])),
                  onMais: () => _opcoes(_lista[i]),
                  onEnviar: () => AnotacaoPdf.compartilhar(_lista[i]),
                ),
              ),
      ),
    );
  }
}

class AnotacaoCard extends StatelessWidget {
  const AnotacaoCard({
    super.key,
    required this.anotacao,
    required this.onTap,
    this.onMais,
    this.onEnviar,
  });

  final Anotacao anotacao;
  final VoidCallback onTap;
  final VoidCallback? onMais;
  final VoidCallback? onEnviar;

  @override
  Widget build(BuildContext context) {
    final trecho = anotacao.corpo.trim().replaceAll(RegExp(r'\s+'), ' ');
    return Vidro(
      onTap: onTap,
      onLongPress: onMais,
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Cores.ciano, Cores.azul],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Cores.ciano.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anotacao.tituloOuPadrao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Cores.texto,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (trecho.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    trecho,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Cores.textoSuave,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  formatarSalvo(anotacao.atualizadoEm),
                  style: TextStyle(
                    color: Cores.ciano.withValues(alpha: 0.8),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (onEnviar != null)
            IconButton(
              tooltip: 'Enviar',
              icon: const Icon(Icons.send_rounded, color: Cores.ciano),
              onPressed: onEnviar,
            ),
          if (onMais != null)
            IconButton(
              tooltip: 'Opções',
              icon: const Icon(Icons.more_vert, color: Cores.textoSuave),
              onPressed: onMais,
            ),
        ],
      ),
    );
  }
}
