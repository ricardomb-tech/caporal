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
      case VarianteLogo.sinFondo:
        colorC = color;
    }

    final centro = Offset(s * 0.47, s * 0.5);
    final grosor = s * 0.155;
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: s * 0.195),
      0.66,
      6.283185 - 1.32,
      false,
      Paint()
        ..color = colorC
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(s * 0.70, s * 0.5), s * 0.078, Paint()..color = Colores.ambar);
  }

  @override
  bool shouldRepaint(covariant _PintorLogo viejo) => viejo.variante != variante || viejo.color != color;
}
