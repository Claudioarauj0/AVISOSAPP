import 'package:flutter/material.dart';

import '../models/departamento.dart';
import '../models/escala.dart';
import '../services/escala_pdf.dart';
import '../services/storage.dart';
import '../theme.dart';
import 'departamentos_screen.dart' show confirmar;
import 'escala_screen.dart';
import 'preview_screen.dart';

/// Escalas já montadas (uma por departamento/mês).
class EscalasScreen extends StatefulWidget {
  const EscalasScreen({super.key});

  @override
  State<EscalasScreen> createState() => _EscalasScreenState();
}

class _EscalasScreenState extends State<EscalasScreen> {
  List<Escala> _lista = Storage.instance.escalas.todos();

  void _recarregar() =>
      setState(() => _lista = Storage.instance.escalas.todos());

  Future<void> _abrir(Widget tela) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
    _recarregar();
  }

  void _editar(Escala e) => _abrir(
    EscalaScreen(departamento: departamentoDa(e), ano: e.ano, mes: e.mes),
  );

  void _opcoes(Escala e) {
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
                onTap: () => acao(() => _editar(e)),
              ),
              ListTile(
                leading: const Icon(Icons.send),
                title: const Text('Enviar PDF (WhatsApp)'),
                onTap: () => acao(() => EscalaPdf.compartilhar(e)),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Visualizar PDF'),
                onTap: () => acao(() => _abrir(PreviewScreen.escala(e))),
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
                onTap: () => acao(() async {
                  final ok = await confirmar(
                    context,
                    'Excluir escala de ${e.departamentoNome}?',
                    'Excluir',
                  );
                  if (!ok) return;
                  await Storage.instance.escalas.excluir(e.id);
                  _recarregar();
                }),
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
        appBar: AppBar(title: const Text('ESCALAS SALVAS')),
        body: _lista.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 56,
                      color: Cores.textoSuave,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nenhuma escala salva ainda.',
                      style: TextStyle(color: Cores.textoSuave),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _lista.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => EscalaCard(
                  escala: _lista[i],
                  onTap: () => _editar(_lista[i]),
                  onMais: () => _opcoes(_lista[i]),
                  onEnviar: () => EscalaPdf.compartilhar(_lista[i]),
                ),
              ),
      ),
    );
  }
}

/// Departamento da escala; se ele foi excluído, recria com o mesmo id/nome.
Departamento departamentoDa(Escala e) =>
    Storage.instance.departamentos.buscar(e.departamentoId) ??
    Departamento(id: e.departamentoId, nome: e.departamentoNome);

class EscalaCard extends StatelessWidget {
  const EscalaCard({
    super.key,
    required this.escala,
    required this.onTap,
    this.onMais,
    this.onEnviar,
  });

  final Escala escala;
  final VoidCallback onTap;
  final VoidCallback? onMais;
  final VoidCallback? onEnviar;

  @override
  Widget build(BuildContext context) {
    final dias = escala.dias.where((d) => d.pessoas.isNotEmpty).length;
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
            child: Icon(
              departamentoDa(escala).iconData,
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
                  'Escala ${escala.departamentoNome}',
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
                  '${nomeMes(escala.ano, escala.mes)}  •  '
                  '$dias dia${dias == 1 ? '' : 's'}',
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
