import 'package:flutter/material.dart';

import 'pantalla_ayuda.dart';
import 'tema.dart';
import 'widgets.dart';

/// Recuperar el acceso. Por ahora se atiende por soporte; sus movimientos siguen en el teléfono.
class PantallaRecuperar extends StatelessWidget {
  const PantallaRecuperar({super.key});

  @override
  Widget build(BuildContext context) {
    return Pantalla(
      titulo: 'Recuperar acceso',
      subtitulo: 'Le ayudamos a entrar',
      hijos: const [
        Text('Escríbanos desde Ayuda con el celular con el que se registró y le ayudamos a recuperar su clave.',
            style: TextStyle(fontSize: 15, color: Colores.gris)),
        Text('Sus movimientos siguen guardados en el teléfono mientras tanto.',
            style: TextStyle(fontSize: 13, color: Colores.gris)),
      ],
      pie: BotonCaporal('Ir a Ayuda',
          icono: Icons.help_outline,
          alTocar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaAyuda()))),
    );
  }
}
