import 'package:flutter/material.dart';

import '../comun/logo_caporal.dart';

/// Pantalla de entrada (diseño "0 · Splash"): degradado verde, logo en cuadro blanco, nombre y lema.
class PantallaSplash extends StatelessWidget {
  const PantallaSplash({super.key});

  static const _verdeArriba = Color(0xFF239B5C);
  static const _verdeAbajo = Color(0xFF0F5F37);

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_verdeArriba, _verdeAbajo],
          ),
        ),
        child: Stack(children: [
          // Círculo claro de fondo, como el horizonte del llano.
          Positioned(
            left: -alto * 0.25,
            right: -alto * 0.25,
            top: alto * 0.48,
            child: Container(
              height: alto,
              decoration: const BoxDecoration(color: Color(0x0FFFFFFF), shape: BoxShape.circle),
            ),
          ),
          SafeArea(
            child: Column(children: [
              const Spacer(flex: 5),
              const LogoCaporal(tam: 128, variante: VarianteLogo.blanco),
              const SizedBox(height: 24),
              const Text('Caporal',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
              const SizedBox(height: 10),
              const Text('Las cuentas de su negocio,\ncon o sin señal',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 17, height: 1.35, color: Color(0xE6FFFFFF))),
              const Spacer(flex: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i == 0 ? Colors.white : const Color(0x66FFFFFF),
                      shape: BoxShape.circle,
                    ),
                  ),
              ]),
              const SizedBox(height: 16),
              const Text('Hecho en Casanare', style: TextStyle(fontSize: 13, color: Color(0xCCFFFFFF))),
              const SizedBox(height: 24),
            ]),
          ),
        ]),
      ),
    );
  }
}
