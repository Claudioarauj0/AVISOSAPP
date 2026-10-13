import 'package:flutter/material.dart';

import '../models/anotacao.dart';
import '../services/anotacao_pdf.dart';
import '../services/storage.dart';
import '../theme.dart';
import 'preview_screen.dart';

class AnotacaoScreen extends StatefulWidget {
  const AnotacaoScreen({super.key, this.anotacao});

  /// Nulo = nova anotação.
  final Anotacao? anotacao;

  @override
  State<AnotacaoScreen> createState() => _AnotacaoScreenState();
}

class _AnotacaoScreenState extends State<AnotacaoScreen> {
  late final Anotacao _nota = widget.anotacao ?? Anotacao.nova();
  late final _titulo = TextEditingController(text: _nota.titulo);
  late final _corpo = TextEditingController(text: _nota.corpo);
  late bool _jaSalva = widget.anotacao != null;
  bool _ocupado = false;

  @override
  void dispose() {
    _titulo.dispose();
    _corpo.dispose();
    super.dispose();
  }

  bool get _alterada =>
      _titulo.text != _nota.titulo || _corpo.text != _nota.corpo;

  /// Salva só se algo mudou, para a hora do salvamento ser sempre a da
  /// última alteração de fato.
  Future<void> _salvar({bool mostrarMsg = true}) async {
    if (!_alterada && _jaSalva) {
      if (mostrarMsg) _msg('Nada novo para salvar');
      return;
    }
    if (_titulo.text.trim().isEmpty && _corpo.text.trim().isEmpty) return;
    _nota
      ..titulo = _titulo.text
      ..corpo = _corpo.text
      ..atualizadoEm = DateTime.now();
    await Storage.instance.anotacoes.salvar(_nota);
    _jaSalva = true;
    if (mounted) setState(() {});
    if (mostrarMsg) _msg('Anotação salva');
  }

  void _msg(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _enviar() async {
    setState(() => _ocupado = true);
    try {
      await _salvar(mostrarMsg: false);
      await AnotacaoPdf.compartilhar(_nota);
    } catch (e) {
      _msg('Erro ao gerar PDF: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _visualizar() async {
    await _salvar(mostrarMsg: false);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen.anotacao(_nota)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // salva automaticamente ao voltar
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _salvar(mostrarMsg: false);
      },
      child: FundoFuturista(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ANOTAÇÃO'),
            actions: [
              IconButton(
                tooltip: 'Salvar',
                icon: const Icon(Icons.save_outlined),
                onPressed: _salvar,
              ),
              IconButton(
                tooltip: 'Visualizar PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: _visualizar,
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // título editável
                  TextField(
                    controller: _titulo,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: Cores.texto,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Título',
                      hintStyle: TextStyle(color: Cores.textoSuave),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      suffixIcon: Icon(Icons.edit_outlined, size: 20),
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Cores.ciano.withValues(alpha: 0.6),
                          Cores.ciano.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  _Carimbo(
                    texto: _jaSalva
                        ? formatarSalvo(_nota.atualizadoEm)
                        : 'Ainda não salvo',
                    ativo: _jaSalva,
                  ),
                  const SizedBox(height: 14),
                  // corpo do texto, justificado como no PDF
                  Expanded(
                    child: Vidro(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: TextField(
                        controller: _corpo,
                        expands: true,
                        maxLines: null,
                        textAlign: TextAlign.justify,
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          color: Cores.texto,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Escreva aqui...',
                          hintStyle: TextStyle(color: Cores.textoSuave),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  BotaoNeon(
                    onTap: _ocupado ? null : _enviar,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: RotuloEnviar(ocupado: _ocupado),
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

/// Indicador "Salvo em ... às ..." com um ponto que brilha quando salvo.
class _Carimbo extends StatelessWidget {
  const _Carimbo({required this.texto, required this.ativo});
  final String texto;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? Cores.ciano : Cores.textoSuave;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
            boxShadow: ativo
                ? [BoxShadow(color: cor.withValues(alpha: 0.8), blurRadius: 8)]
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(color: cor, fontSize: 13, letterSpacing: 0.5),
        ),
      ],
    );
  }
}
