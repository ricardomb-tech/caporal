import 'package:flutter/material.dart';

import '../sync/recuperacion.dart';
import 'campo_caporal.dart';
import 'pantalla_codigo.dart';
import 'tema.dart';
import 'widgets.dart';

/// Paso 1 de recuperar el acceso: el celular al que se manda el código.
class PantallaRecuperar extends StatefulWidget {
  const PantallaRecuperar({super.key});

  @override
  State<PantallaRecuperar> createState() => _PantallaRecuperarState();
}

class _PantallaRecuperarState extends State<PantallaRecuperar> {
  final _celular = TextEditingController();
  final _cliente = ClienteRecuperacion();
  bool _enviando = false;
  String? _error;

  Future<void> _enviar() async {
    final celular = _celular.text.trim();
    if (!RegExp(r'^3\d{9}$').hasMatch(celular)) {
      setState(() => _error = 'El celular debe tener 10 números y empezar por 3.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    final error = await _cliente.pedirCodigo(celular);
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _error = error;
    });
    if (error == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaCodigo(celular: celular)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Pantalla(
      titulo: 'Recuperar acceso',
      subtitulo: 'Le enviamos un código',
      hijos: [
        const Text('Escriba el celular con el que se registró y le mandamos un código de 6 números por mensaje.',
            style: TextStyle(fontSize: 15, color: Colores.gris)),
        CampoCaporal(
            etiqueta: 'Celular',
            icono: Icons.person_outline,
            controlador: _celular,
            pista: '310 123 4567',
            teclado: TextInputType.phone),
        if (_error != null) Text(_error!, style: const TextStyle(color: Colores.rojo, fontSize: 15)),
        const Text('Sus movimientos siguen guardados en el teléfono mientras tanto.',
            style: TextStyle(fontSize: 13, color: Colores.gris)),
      ],
      pie: BotonCaporal(_enviando ? 'Enviando…' : 'Enviar código', alTocar: _enviando ? null : _enviar),
    );
  }
}
