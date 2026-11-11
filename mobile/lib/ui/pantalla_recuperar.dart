import 'package:flutter/material.dart';

import 'tema.dart';
import 'widgets.dart';

/// Recuperar el acceso con un código por mensaje.
/// Pendiente en el servidor: el envío del código (proveedor de SMS) aún no está contratado.
class PantallaRecuperar extends StatefulWidget {
  const PantallaRecuperar({super.key});

  @override
  State<PantallaRecuperar> createState() => _PantallaRecuperarState();
}

class _PantallaRecuperarState extends State<PantallaRecuperar> {
  final _celular = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Pantalla(
      titulo: 'Recuperar acceso',
      subtitulo: 'Le enviamos un código',
      hijos: [
        const Text('Escriba el celular con el que se registró y le mandamos un código de 6 números por mensaje.',
            style: TextStyle(fontSize: 15, color: Colores.gris)),
        TextField(
            controller: _celular, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Celular')),
        const Text('Sus movimientos siguen guardados en el teléfono mientras tanto.',
            style: TextStyle(fontSize: 13, color: Colores.gris)),
      ],
      pie: BotonCaporal('Enviar código', alTocar: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Esta función se activa en la siguiente versión. Escríbanos desde Ayuda y le ayudamos.')));
      }),
    );
  }
}
