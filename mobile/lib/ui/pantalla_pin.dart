import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/sesion.dart';
import 'tema.dart';
import 'widgets.dart';

enum ModoPin { entrar, crear }

/// PIN de 4 números: candado de comodidad para que otra persona no abra las cuentas.
class PantallaPin extends StatefulWidget {
  final ModoPin modo;
  const PantallaPin({super.key, this.modo = ModoPin.entrar});

  @override
  State<PantallaPin> createState() => _PantallaPinState();
}

class _PantallaPinState extends State<PantallaPin> {
  String _pin = '';
  String? _primero;
  String? _mensaje;
  int _fallos = 0;
  DateTime? _bloqueadoHasta;

  Future<void> _tecla(String t) async {
    if (_bloqueadoHasta != null && DateTime.now().isBefore(_bloqueadoHasta!)) {
      setState(() => _mensaje = 'Espere un momento antes de intentar de nuevo.');
      return;
    }
    setState(() {
      _mensaje = null;
      if (t == '⌫') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < 4) {
        _pin += t;
      }
    });
    if (_pin.length < 4) return;

    final sesion = context.read<Sesion>();
    if (widget.modo == ModoPin.crear) {
      if (_primero == null) {
        setState(() {
          _primero = _pin;
          _pin = '';
          _mensaje = 'Escríbalo otra vez para confirmar';
        });
      } else if (_primero == _pin) {
        await sesion.guardarPin(_pin);
        if (mounted) Navigator.pop(context);
      } else {
        setState(() {
          _primero = null;
          _pin = '';
          _mensaje = 'No coinciden. Empecemos de nuevo.';
        });
      }
    } else {
      final ok = await sesion.verificarPin(_pin);
      if (!ok && mounted) {
        _fallos++;
        setState(() {
          _pin = '';
          _mensaje = 'PIN incorrecto';
          if (_fallos >= 5) {
            _bloqueadoHasta = DateTime.now().add(const Duration(seconds: 30));
            _fallos = 0;
            _mensaje = 'Demasiados intentos. Espere 30 segundos.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final crear = widget.modo == ModoPin.crear;
    return Scaffold(
      appBar: crear ? AppBar() : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            Insignia.icono(Icons.lock_outline, Colores.verde, tam: 72),
            const SizedBox(height: 12),
            Text(crear ? (_primero == null ? 'Cree su PIN' : 'Confirme su PIN') : 'Escriba su PIN',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_mensaje ?? 'Protege sus cuentas si pierde el teléfono',
                style: TextStyle(fontSize: 14, color: _mensaje != null && _mensaje!.startsWith('P') ? Colores.rojo : Colores.gris)),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 4; i++)
                Container(
                  margin: const EdgeInsets.all(8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i < _pin.length ? Colores.verde : const Color(0xFFD5D9D3)),
                ),
            ]),
            const Spacer(),
            for (final fila in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '⌫'],
            ])
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final t in fila)
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: SizedBox(
                      width: 92,
                      height: 60,
                      child: t.isEmpty
                          ? null
                          : Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => _tecla(t),
                                child: Center(child: Text(t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600))),
                              ),
                            ),
                    ),
                  ),
              ]),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}
