import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/sesion.dart';
import 'pantalla_recuperar.dart';
import 'pantalla_registro.dart';
import 'tema.dart';
import 'widgets.dart';

/// Entrar con celular y clave. Crear la cuenta es otra pantalla de tres pasos.
class PantallaIngreso extends StatefulWidget {
  const PantallaIngreso({super.key});

  @override
  State<PantallaIngreso> createState() => _PantallaIngresoState();
}

class _PantallaIngresoState extends State<PantallaIngreso> {
  final _celular = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false;
  bool _ver = false;
  String? _error;

  Future<void> _entrar() async {
    final sesion = context.read<Sesion>();
    setState(() {
      _cargando = true;
      _error = null;
    });
    final error = await sesion.ingresar(_celular.text.trim(), _clave.text);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            const LogoCaporal(tam: 64, color: Colores.verde),
            const SizedBox(height: 16),
            const Text('Bienvenido', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text('Entre a las cuentas de su negocio', style: TextStyle(fontSize: 16, color: Colores.gris)),
            const SizedBox(height: 28),
            TextField(
                controller: _celular,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Su celular')),
            const SizedBox(height: 12),
            TextField(
              controller: _clave,
              obscureText: !_ver,
              decoration: InputDecoration(
                labelText: 'Su clave',
                suffixIcon: IconButton(
                    icon: Icon(_ver ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _ver = !_ver)),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRecuperar())),
                child: const Text('¿Olvidó su clave?'),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colores.rojo, fontSize: 15)),
              ),
            BotonCaporal(_cargando ? 'Un momento…' : 'Entrar', alTocar: _cargando ? null : _entrar),
            const SizedBox(height: 8),
            BotonCaporal('Soy nuevo, crear mi cuenta',
                estilo: EstiloBoton.contorno,
                alTocar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaRegistro()))),
          ],
        ),
      ),
    );
  }
}
