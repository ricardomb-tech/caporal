import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/sesion.dart';
import 'tema.dart';
import 'widgets.dart';

/// Datos personales de quien usa la app. Se guardan en el teléfono.
class PantallaMisDatos extends StatefulWidget {
  const PantallaMisDatos({super.key});

  @override
  State<PantallaMisDatos> createState() => _PantallaMisDatosState();
}

class _PantallaMisDatosState extends State<PantallaMisDatos> {
  late final _nombre = TextEditingController(text: context.read<Sesion>().nombrePersona ?? '');
  late final _correo = TextEditingController(text: context.read<Sesion>().correo ?? '');

  @override
  Widget build(BuildContext context) {
    final sesion = context.read<Sesion>();
    return Pantalla(
      titulo: 'Mis datos personales',
      subtitulo: 'Solo usted los ve',
      hijos: [
        TextField(controller: _nombre, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Su nombre completo')),
        TextField(controller: _correo, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo (opcional)')),
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Su celular'),
          child: Text(sesion.celular ?? '—', style: const TextStyle(fontSize: 16, color: Colores.gris)),
        ),
        const Text('El celular es su usuario y no se puede cambiar aquí. Si necesita cambiarlo, escríbanos desde Ayuda.',
            style: TextStyle(fontSize: 13, color: Colores.gris)),
      ],
      pie: BotonCaporal('Guardar cambios', icono: Icons.check, alTocar: () async {
        final navegador = Navigator.of(context);
        await sesion.guardarDatosPersonales(nombre: _nombre.text.trim(), correoNuevo: _correo.text.trim());
        navegador.pop();
      }),
    );
  }
}
