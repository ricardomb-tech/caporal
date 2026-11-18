import 'package:flutter/material.dart';

import '../ajustes/pantalla_ajustes.dart';
import '../clientes/pantalla_deudores.dart';
import 'pantalla_inicio.dart';
import '../movimientos/pantalla_resumen.dart';
import '../comun/widgets.dart';

/// Contenedor de las cuatro pestañas con la navegación flotante de vidrio.
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _actual = 0;

  /// En la pestaña Deudas: false muestra "Le deben"; true, "Le debo".
  final _verDebo = ValueNotifier(false);

  @override
  void dispose() {
    _verDebo.dispose();
    super.dispose();
  }

  void _verDeudas({bool debo = false}) => setState(() {
        _verDebo.value = debo;
        _actual = 1;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _actual, children: [
        PantallaInicio(verDeudores: _verDeudas),
        PantallaDeudores(verDebo: _verDebo),
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
