import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../sincronizacion/sesion.dart';
import '../comun/formulario_guiado.dart';

/// Datos personales de quien usa la app, paso a paso. Se guardan solo en el teléfono.
class PantallaMisDatos extends StatefulWidget {
  const PantallaMisDatos({super.key});

  @override
  State<PantallaMisDatos> createState() => _PantallaMisDatosState();
}

class _PantallaMisDatosState extends State<PantallaMisDatos> {
  late final _nombre = TextEditingController(text: context.read<Sesion>().nombrePersona ?? '');
  late final _correo = TextEditingController(text: context.read<Sesion>().correo ?? '');

  Future<String?> _guardar() async {
    final sesion = context.read<Sesion>();
    final navegador = Navigator.of(context);
    await sesion.guardarDatosPersonales(nombre: _nombre.text.trim(), correoNuevo: _correo.text.trim());
    navegador.pop();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final celular = context.read<Sesion>().celular ?? '—';
    return FormularioGuiado(
      titulo: 'Mis datos personales',
      textoFinal: 'Guardar cambios',
      alTerminar: _guardar,
      pasos: [
        PasoTexto(
          pregunta: '¿Cómo se llama?',
          ayuda: 'Su nombre completo. Firma los recordatorios de cobro. Su celular ($celular) es su usuario y no se '
              'cambia aquí; si lo necesita, escríbanos desde Ayuda.',
          ejemplo: 'Marta Pérez Rodríguez',
          etiqueta: 'Su nombre completo',
          controlador: _nombre,
          mayusculas: TextCapitalization.words,
          validador: (v) => v.length < 3 ? 'Escriba su nombre completo, por favor.' : null,
        ),
        PasoTexto(
          pregunta: '¿Tiene correo electrónico?',
          ayuda: 'Es opcional. Nos sirve para ayudarle si un día no puede entrar.',
          ejemplo: 'marta@gmail.com',
          etiqueta: 'Correo (opcional)',
          controlador: _correo,
          teclado: TextInputType.emailAddress,
          opcional: true,
          validador: (v) => v.contains('@') && v.contains('.') ? null : 'Revise el correo: le falta la @ o el punto.',
        ),
      ],
    );
  }
}
