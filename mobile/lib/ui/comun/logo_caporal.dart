import 'package:flutter/material.dart';

import 'tema.dart';

/// Cómo se ve el símbolo según el fondo donde va (ver "Marca" en el diseño).
enum VarianteLogo {
  /// Ícono de la app: cuadro verde con degradado y C blanca.
  icono,

  /// Cuadro blanco con borde y C verde.
  claro,

  /// Cuadro tinta con C blanca.
  oscuro,

  /// Cuadro blanco sin borde y C verde (sobre fondos verdes, como el splash).
  blanco,

  /// Solo la C, sin cuadro (para ponerla sobre un fondo propio).
  sinFondo,
}

/// Símbolo de Caporal: la C abraza un sol ámbar (el sol del llano y la moneda del negocio).
class LogoCaporal extends StatelessWidget {
  final double tam;
  final VarianteLogo variante;

  /// Color de la C cuando la variante es [VarianteLogo.sinFondo].
  final Color color;

  const LogoCaporal({super.key, this.tam = 64, this.variante = VarianteLogo.icono, this.color = Colors.white});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(tam, tam), painter: _PintorLogo(variante, color));
}

/// La C de Caporal en un cuadro de lado [s]: anillo con hueco central y una ranura recta hacia la derecha,
/// donde se asoma el sol (ver "Marca" en el diseño). La usan el logo en pantalla y el ícono de la app.
Path rutaC(double s) {
  final c = Offset(s * 0.5, s * 0.5);
  final anillo = Path()..addOval(Rect.fromCircle(center: c, radius: s * 0.28));
  final hueco = Path()..addOval(Rect.fromCircle(center: c, radius: s * 0.12));
  final alto = s * 0.17;
  final ranura = Path()
    ..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(c.dx, c.dy - alto / 2, s * 0.32, alto),
      Radius.circular(alto / 2),
    ));
  return Path.combine(PathOperation.difference, Path.combine(PathOperation.difference, anillo, hueco), ranura);
}

class _PintorLogo extends CustomPainter {
  static const _verdeArriba = Color(0xFF239B5C);
  static const _verdeAbajo = Color(0xFF0F5F37);

  final VarianteLogo variante;
  final Color color;
  _PintorLogo(this.variante, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cuadro = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.22));
    var colorC = Colors.white;

    switch (variante) {
      case VarianteLogo.icono:
        canvas.drawRRect(
          cuadro,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_verdeArriba, _verdeAbajo],
            ).createShader(Offset.zero & size),
        );
      case VarianteLogo.claro:
        canvas.drawRRect(cuadro.deflate(0.5), Paint()..color = Colors.white);
        canvas.drawRRect(
            cuadro.deflate(0.5),
            Paint()
              ..color = const Color(0xFFE4E7E2)
              ..style = PaintingStyle.stroke);
        colorC = Colores.verde;
      case VarianteLogo.oscuro:
        canvas.drawRRect(cuadro, Paint()..color = Colores.texto);
      case VarianteLogo.blanco:
        canvas.drawRRect(cuadro, Paint()..color = Colors.white);
        colorC = Colores.verde;
      case VarianteLogo.sinFondo:
        colorC = color;
    }

    canvas.drawPath(rutaC(s), Paint()..color = colorC);
    canvas.drawCircle(Offset(s * 0.70, s * 0.5), s * 0.075, Paint()..color = Colores.ambar);
  }

  @override
  bool shouldRepaint(covariant _PintorLogo viejo) => viejo.variante != variante || viejo.color != color;
}
