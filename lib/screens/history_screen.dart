import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/aviso.dart';
import '../services/pdf_service.dart';
import '../services/storage.dart';
import '../theme.dart';
import 'form_screen.dart';
import 'preview_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Aviso> _lista = Storage.instance.avisos.todos();

  void _recarregar() =>
      setState(() => _lista = Storage.instance.avisos.todos());

  Future<void> _abrir(Widget tela) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
    _recarregar();
  }

  Future<void> _excluir(Aviso a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir aviso?'),
        content: Text(titulo(a)),
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
      await Storage.instance.avisos.excluir(a.id);
      _recarregar();
    }
  }

  void _opcoes(Aviso a) {
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
                onTap: () => acao(() => _abrir(FormScreen(aviso: a))),
              ),
              ListTile(
                leading: const Icon(Icons.send),
                title: const Text('Enviar PDF (WhatsApp)'),
                onTap: () => acao(() => PdfService.compartilhar(a)),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Visualizar PDF'),
                onTap: () => acao(() => _abrir(PreviewScreen.aviso(a))),
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Usar como modelo'),
                subtitle: const Text('Cria um novo aviso a partir deste'),
                onTap: () =>
                    acao(() => _abrir(FormScreen(aviso: a.duplicar()))),
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
                onTap: () => acao(() => _excluir(a)),
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
        appBar: AppBar(title: const Text('ÚLTIMOS AVISOS')),
        body: _lista.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 56,
                      color: Cores.textoSuave,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nenhum aviso salvo ainda.',
                      style: TextStyle(color: Cores.textoSuave),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _lista.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => AvisoCard(
                  aviso: _lista[i],
                  onTap: () => _abrir(FormScreen(aviso: _lista[i])),
                  onMais: () => _opcoes(_lista[i]),
                  onEnviar: () => PdfService.compartilhar(_lista[i]),
                ),
              ),
      ),
    );
  }
}

String titulo(Aviso a) => a.culto.trim().isEmpty ? 'Culto' : a.culto.trim();

class AvisoCard extends StatelessWidget {
  const AvisoCard({
    super.key,
    required this.aviso,
    required this.onTap,
    this.onMais,
    this.onEnviar,
  });

  final Aviso aviso;
  final VoidCallback onTap;
  final VoidCallback? onMais;
  final VoidCallback? onEnviar;

  @override
  Widget build(BuildContext context) {
    final sub = aviso.data != null
        ? formatarData(aviso.data)
        : 'Editado em ${DateFormat('dd/MM/yyyy HH:mm').format(aviso.atualizadoEm)}';
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
              gradient: Cores.gradienteAcao,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Cores.azul.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo(aviso),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Cores.texto,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sub,
                  style: const TextStyle(
                    color: Cores.textoSuave,
                    fontSize: 12.5,
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
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right, color: Cores.textoSuave),
            ),
        ],
      ),
    );
  }
}
