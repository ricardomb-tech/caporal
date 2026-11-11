import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/movimiento.dart';
import '../data/repositorio.dart';
import '../formato.dart';
import 'tema.dart';

/// Registro en tres toques: elegir qué pasó (desde el inicio), poner el valor y guardar.
class PantallaRegistrar extends StatefulWidget {
  final TipoMovimiento tipo;
  const PantallaRegistrar({super.key, required this.tipo});

  @override
  State<PantallaRegistrar> createState() => _PantallaRegistrarState();
}

class _PantallaRegistrarState extends State<PantallaRegistrar> {
  String _digitos = '';
  final _cliente = TextEditingController();
  bool _guardando = false;

  int get _valor => _digitos.isEmpty ? 0 : int.parse(_digitos);
  bool get _esFiado => widget.tipo == TipoMovimiento.fiado;

  String get _titulo => switch (widget.tipo) {
        TipoMovimiento.venta => 'Vendí',
        TipoMovimiento.gasto => 'Gasté',
        TipoMovimiento.fiado => 'Fié',
        TipoMovimiento.abono => 'Me pagaron',
      };

  void _tecla(String t) {
    setState(() {
      if (t == 'Borrar') {
        if (_digitos.isNotEmpty) _digitos = _digitos.substring(0, _digitos.length - 1);
      } else if (_digitos.length + t.length <= 9) {
        _digitos = (_digitos + t).replaceFirst(RegExp(r'^0+'), '');
      }
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    await context.read<Repositorio>().registrar(
          tipo: widget.tipo,
          valor: _valor,
          clienteNombre: _esFiado ? _cliente.text.trim() : null,
          medioPago: widget.tipo == TipoMovimiento.venta ? 'EFECTIVO' : null,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listo, anotado: ${pesos(_valor)}')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final puedeGuardar = _valor > 0 && !_guardando && (!_esFiado || _cliente.text.trim().isNotEmpty);
    return Scaffold(
      appBar: AppBar(title: Text(_titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(children: [
            if (_esFiado)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _cliente,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: '¿A quién le fió?'),
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text(pesos(_valor),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colores.verde)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(children: [
                for (final fila in const [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                  ['000', '0', 'Borrar'],
                ])
                  Expanded(
                    child: Row(children: [
                      for (final t in fila)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _tecla(t),
                                child: Center(
                                  child: Text(t,
                                      style: TextStyle(
                                          fontSize: t == 'Borrar' ? 16 : 26,
                                          fontWeight: FontWeight.w600,
                                          color: t == 'Borrar' ? Colores.rojo : Colores.texto)),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: puedeGuardar ? _guardar : null, child: const Text('Guardar')),
          ]),
        ),
      ),
    );
  }
}
