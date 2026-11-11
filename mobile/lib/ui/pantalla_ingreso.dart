import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sync/sesion.dart';
import 'tema.dart';

class PantallaIngreso extends StatefulWidget {
  const PantallaIngreso({super.key});

  @override
  State<PantallaIngreso> createState() => _PantallaIngresoState();
}

class _PantallaIngresoState extends State<PantallaIngreso> {
  final _celular = TextEditingController();
  final _clave = TextEditingController();
  final _negocio = TextEditingController();
  final _municipio = TextEditingController(text: 'Yopal');
  bool _esNuevo = true;
  bool _acepta = false;
  bool _cargando = false;
  String? _error;

  Future<void> _continuar() async {
    final sesion = context.read<Sesion>();
    setState(() {
      _cargando = true;
      _error = null;
    });
    final error = _esNuevo
        ? await sesion.registrar(
            celular: _celular.text.trim(),
            nombreNegocio: _negocio.text.trim(),
            municipio: _municipio.text.trim(),
            clave: _clave.text,
            aceptaDatos: _acepta)
        : await sesion.ingresar(_celular.text.trim(), _clave.text);
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
            const SizedBox(height: 24),
            const Text('Caporal', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colores.verde)),
            const Text('Las cuentas de su negocio, con o sin señal',
                style: TextStyle(fontSize: 16, color: Colores.gris)),
            const SizedBox(height: 32),
            if (_esNuevo) ...[
              TextField(controller: _negocio, decoration: const InputDecoration(labelText: 'Nombre de su negocio')),
              const SizedBox(height: 12),
              TextField(controller: _municipio, decoration: const InputDecoration(labelText: 'Municipio')),
              const SizedBox(height: 12),
            ],
            TextField(
                controller: _celular,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Su celular')),
            const SizedBox(height: 12),
            TextField(
                controller: _clave,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Clave (mínimo 8 caracteres)')),
            if (_esNuevo)
              CheckboxListTile(
                value: _acepta,
                onChanged: (v) => setState(() => _acepta = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Acepto la política de tratamiento de datos personales (Ley 1581 de 2012)'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_error!, style: const TextStyle(color: Colores.rojo, fontSize: 15)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _cargando || (_esNuevo && !_acepta) ? null : _continuar,
              child: Text(_cargando ? 'Un momento…' : (_esNuevo ? 'Crear mi cuenta' : 'Entrar')),
            ),
            TextButton(
              onPressed: () => setState(() => _esNuevo = !_esNuevo),
              child: Text(_esNuevo ? 'Ya tengo cuenta' : 'Soy nuevo, quiero crear mi cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
