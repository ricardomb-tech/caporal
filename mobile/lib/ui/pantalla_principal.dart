import 'package:flutter/material.dart';

import 'pantalla_ajustes.dart';
import 'pantalla_deudores.dart';
import 'pantalla_inicio.dart';
import 'pantalla_resumen.dart';
import 'widgets.dart';

/// Contenedor de las cuatro pestañas con la navegación flotante de vidrio.
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _actual = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _actual, children: [
        PantallaInicio(verDeudores: () => setState(() => _actual = 1)),
        const PantallaDeudores(),
        const PantallaResumen(),
        const PantallaAjustes(),
      ]),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SafeArea(top: false, child: NavFlotante(actual: _actual, alTocar: (i) => setState(() => _actual = i))),
      ),
    );
  }
}
