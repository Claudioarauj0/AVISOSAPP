import 'package:flutter/material.dart';

import '../theme.dart';

const logoBranca = 'assets/images/logo_branca.png';

/// Logo branca com um halo azul por trás.
class Logo extends StatelessWidget {
  const Logo({super.key, this.altura = 110, this.brilho = true});
  final double altura;
  final bool brilho;

  @override
  Widget build(BuildContext context) {
    final imagem = Image.asset(logoBranca, height: altura);
    if (!brilho) return imagem;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: altura * 1.6,
          height: altura * 1.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Cores.azul.withValues(alpha: 0.45),
                Cores.azul.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        imagem,
      ],
    );
  }
}
