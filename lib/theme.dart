import 'dart:ui';

import 'package:flutter/material.dart';

/// Paleta azul-marinho da identidade Verbo da Vida.
class Cores {
  static const fundoEscuro = Color(0xFF020817);
  static const fundo = Color(0xFF06123A);
  static const marinho = Color(0xFF0A1A4A);
  static const azul = Color(0xFF2F6BFF);
  static const ciano = Color(0xFF4FD8FF);
  static const texto = Color(0xFFEAF1FF);
  static const textoSuave = Color(0xFF8FA3CC);
  static const vidro = Color(0x14FFFFFF);
  static const vidroBorda = Color(0x26FFFFFF);

  static const gradienteAcao = LinearGradient(
    colors: [azul, ciano],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

ThemeData temaApp() {
  final raio = BorderRadius.circular(14);
  OutlineInputBorder borda(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: raio,
    borderSide: BorderSide(color: c, width: w),
  );

  final esquema = ColorScheme.fromSeed(
    seedColor: Cores.azul,
    brightness: Brightness.dark,
    primary: Cores.ciano,
    onPrimary: Cores.fundoEscuro,
    surface: const Color(0xFF0B1840),
    onSurface: Cores.texto,
  );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: esquema,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Cores.fundo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Cores.texto,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Cores.texto,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 4,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x0DFFFFFF),
      labelStyle: const TextStyle(color: Cores.textoSuave),
      floatingLabelStyle: const TextStyle(color: Cores.ciano),
      border: borda(Cores.vidroBorda),
      enabledBorder: borda(Cores.vidroBorda),
      focusedBorder: borda(Cores.ciano, 1.6),
      suffixIconColor: Cores.textoSuave,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Cores.ciano,
      selectionHandleColor: Cores.ciano,
      selectionColor: Color(0x554FD8FF),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xFF13245A),
      contentTextStyle: TextStyle(color: Cores.texto),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF0B1840),
      dragHandleColor: Cores.textoSuave,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0B1840)),
    listTileTheme: const ListTileThemeData(iconColor: Cores.ciano),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Cores.ciano),
    ),
  );
}

/// Fundo azul-marinho com brilhos difusos, inspirado na arte da logo.
class FundoFuturista extends StatelessWidget {
  const FundoFuturista({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Cores.fundo, Cores.fundoEscuro],
        ),
      ),
      child: Stack(
        children: [
          const _Brilho(top: -120, right: -100, cor: Cores.azul, tam: 340),
          const _Brilho(bottom: -140, left: -120, cor: Cores.azul, tam: 380),
          const _Brilho(
            top: 260,
            left: -160,
            cor: Cores.ciano,
            tam: 220,
            opacidade: 0.10,
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Brilho extends StatelessWidget {
  const _Brilho({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.cor,
    required this.tam,
    this.opacidade = 0.28,
  });
  final double? top, left, right, bottom;
  final Color cor;
  final double tam;
  final double opacidade;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: tam,
          height: tam,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                cor.withValues(alpha: opacidade),
                cor.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão de "vidro" fosco.
class Vidro extends StatelessWidget {
  const Vidro({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.raio = 18,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double raio;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(raio);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Cores.vidro,
          shape: RoundedRectangleBorder(
            borderRadius: r,
            side: const BorderSide(color: Cores.vidroBorda),
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: r,
            splashColor: Cores.ciano.withValues(alpha: 0.12),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Botão principal com degradê azul → ciano e brilho.
class BotaoNeon extends StatelessWidget {
  const BotaoNeon({
    super.key,
    required this.child,
    required this.onTap,
    this.raio = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double raio;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(raio);
    final ativo = onTap != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: ativo ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: Cores.gradienteAcao,
          boxShadow: [
            BoxShadow(
              color: Cores.azul.withValues(alpha: 0.55),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: r,
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
                child: IconTheme.merge(
                  data: const IconThemeData(color: Colors.white),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de seção: texto espaçado em ciano com uma linha que some.
class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key, this.acao});
  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Cores.ciano, Cores.azul],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Cores.ciano.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            texto.toUpperCase(),
            style: const TextStyle(
              color: Cores.ciano,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Cores.ciano.withValues(alpha: 0.4),
                    Cores.ciano.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          ?acao,
        ],
      ),
    );
  }
}

/// Conteúdo do botão "GERAR PDF E ENVIAR". Encolhe se não couber (fonte do
/// celular aumentada) em vez de quebrar o layout.
class RotuloEnviar extends StatelessWidget {
  const RotuloEnviar({super.key, this.ocupado = false});
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    // Center ocupa a largura toda: o botão fica do tamanho da tela e com o
    // texto no meio, mesmo dentro de colunas alinhadas à esquerda.
    return Center(
      heightFactor: 1,
      child: FittedBox(fit: BoxFit.scaleDown, child: _conteudo()),
    );
  }

  Widget _conteudo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ocupado
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded),
        const SizedBox(width: 12),
        const Text('GERAR PDF E ENVIAR'),
      ],
    );
  }
}
