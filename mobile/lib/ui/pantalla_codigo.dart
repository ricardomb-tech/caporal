import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/recuperacion.dart';
import '../sync/sesion.dart';
import 'campo_caporal.dart';
import 'tema.dart';
import 'widgets.dart';

/// Paso 2 de recuperar el acceso: el código recibido y la clave nueva.
class PantallaCodigo extends StatefulWidget {
  final String celular;
  const PantallaCodigo({super.key, required this.celular});

  @override
  State<PantallaCodigo> createState() => _PantallaCodigoState();
}

class _PantallaCodigoState extends State<PantallaCodigo> {
  final _codigo = TextEditingController();
  final _clave = TextEditingController();
  final _cliente = ClienteRecuperacion();
  bool _ver = false;
  bool _enviando = false;
  String? _error;
  String? _aviso;

  Future<void> _cambiar() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_codigo.text.trim())) {
      setState(() => _error = 'El código tiene 6 números.');
      return;
    }
    if (_clave.text.length < 8) {
      setState(() => _error = 'La clave debe tener mínimo 8 caracteres.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    final error = await context
        .read<Sesion>()
        .restablecerClave(celular: widget.celular, codigo: _codigo.text.trim(), clave: _clave.text);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    // La sesión quedó abierta: se cierran las pantallas de recuperación y la app muestra el inicio.
    Navigator.popUntil(context, (ruta) => ruta.isFirst);
  }

  Future<void> _reenviar() async {
    final error = await _cliente.pedirCodigo(widget.celular);
    if (!mounted) return;
    setState(() {
      _error = error;
      _aviso = error == null ? 'Le enviamos un código nuevo.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Pantalla(
      titulo: 'Escriba el código',
      subtitulo: 'Enviado al ${widget.celular}',
      hijos: [
        CampoCaporal(
            etiqueta: 'Código de 6 números',
            icono: Icons.sms_outlined,
            controlador: _codigo,
            pista: '123456',
            teclado: TextInputType.number),
        CampoCaporal(
          etiqueta: 'Clave nueva',
          icono: Icons.lock_outline,
          controlador: _clave,
          pista: 'Mínimo 8 caracteres',
          oculto: !_ver,
          sufijo: IconButton(
              icon: Icon(_ver ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _ver = !_ver)),
        ),
        if (_error != null) Text(_error!, style: const TextStyle(color: Colores.rojo, fontSize: 15)),
        if (_aviso != null) Text(_aviso!, style: const TextStyle(color: Colores.verde, fontSize: 15)),
        GestureDetector(
          onTap: _reenviar,
          child: const Text('¿No le llegó? Enviar otro código',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colores.verde)),
        ),
      ],
      pie: BotonCaporal(_enviando ? 'Un momento…' : 'Cambiar clave y entrar', alTocar: _enviando ? null : _cambiar),
    );
  }
}
