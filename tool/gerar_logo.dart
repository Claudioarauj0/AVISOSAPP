// Gera as versões da logo a partir de tool/logo_original.jpg:
//   logo_branca.png  -> símbolo branco com fundo transparente (app)
//   icone_frente.png -> símbolo com margem para o ícone adaptativo do Android
// Uso: dart run tool/gerar_logo.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final original = img.decodeJpg(
    File('tool/logo_original.jpg').readAsBytesSync(),
  )!;

  // recorta só o símbolo (a imagem tem 1080x1080)
  final s = original.width / 1080;
  final recorte = img.copyCrop(
    original,
    x: (180 * s).round(),
    y: (215 * s).round(),
    width: (720 * s).round(),
    height: (650 * s).round(),
  );

  img.Image pintar(int r, int g, int b) {
    final out = img.Image(
      width: recorte.width,
      height: recorte.height,
      numChannels: 4,
    );
    for (final p in recorte) {
      // fundo azul tem luminância baixa; o símbolo é branco
      final lum = (p.r * 0.299 + p.g * 0.587 + p.b * 0.114);
      final a = ((lum - 70) / (230 - 70) * 255).clamp(0, 255).round();
      out.setPixelRgba(p.x, p.y, r, g, b, a);
    }
    return out;
  }

  File(
    'assets/images/logo_branca.png',
  ).writeAsBytesSync(img.encodePng(pintar(255, 255, 255)));

  // ícone adaptativo: o Android corta as bordas, então o símbolo ocupa ~55%
  final branca = pintar(255, 255, 255);
  final icone = img.Image(width: 1024, height: 1024, numChannels: 4);
  final larg = (1024 * 0.55).round();
  final alt = (larg * branca.height / branca.width).round();
  img.compositeImage(
    icone,
    img.copyResize(branca, width: larg, height: alt),
    dstX: (1024 - larg) ~/ 2,
    dstY: (1024 - alt) ~/ 2,
  );
  Directory('tool/gerado').createSync();
  File('tool/gerado/icone_frente.png').writeAsBytesSync(img.encodePng(icone));
  // ignore: avoid_print
  print('ok');
}
