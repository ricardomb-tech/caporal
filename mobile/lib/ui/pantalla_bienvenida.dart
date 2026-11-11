import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/sesion.dart';
import 'tema.dart';
import 'widgets.dart';

/// Pantalla verde de arranque con el logo.
class PantallaSplash extends StatelessWidget {
  const PantallaSplash({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Colores.verde,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            LogoCaporal(tam: 110),
            SizedBox(height: 20),
            Text('Caporal', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 6),
            Text('Las cuentas de su negocio', style: TextStyle(fontSize: 16, color: Color(0xCCFFFFFF))),
          ]),
        ),
      );
}

/// Tres pantallas cortas que explican lo esencial, solo la primera vez.
class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key});

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida> {
  final _control = PageController();
  int _pagina = 0;

  static const _paginas = [
    (Icons.touch_app_outlined, 'Anote en segundos', 'Venta, gasto o fiado con tres toques. Sin libreta y sin complicaciones.'),
    (Icons.wifi_off_outlined, 'Funciona sin señal', 'Todo queda guardado en su celular y se envía solo cuando vuelve el Internet.'),
    (Icons.people_outline, 'Sepa quién le debe', 'Vea cuánto le deben y cobre por WhatsApp con un toque.'),
  ];

  @override
  Widget build(BuildContext context) {
    final ultima = _pagina == _paginas.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => context.read<Sesion>().marcarBienvenida(), child: const Text('Saltar')),
            ),
            Expanded(
              child: PageView(
                controller: _control,
                onPageChanged: (i) => setState(() => _pagina = i),
                children: [
                  for (final p in _paginas)
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Insignia.icono(p.$1, Colores.verde, tam: 160),
                      const SizedBox(height: 32),
                      Text(p.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(p.$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, color: Colores.gris)),
                    ]),
                ],
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _paginas.length; i++)
                Container(
                  margin: const EdgeInsets.all(4),
                  width: i == _pagina ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: i == _pagina ? Colores.verde : const Color(0xFFD5D9D3), borderRadius: BorderRadius.circular(4)),
                ),
            ]),
            const SizedBox(height: 20),
            BotonCaporal(ultima ? 'Empezar' : 'Siguiente', alTocar: () {
              if (ultima) {
                context.read<Sesion>().marcarBienvenida();
              } else {
                _control.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
              }
            }),
          ]),
        ),
      ),
    );
  }
}
