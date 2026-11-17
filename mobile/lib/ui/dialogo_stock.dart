import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/inventario.dart';
import '../data/producto.dart';
import 'tema.dart';
import 'widgets.dart';

enum _Modo { entro, perdi, conte }

/// Anotar una cantidad: llegó mercancía, se perdió o regaló algo, o se contó lo que hay.
Future<void> mostrarDialogoStock(BuildContext context, Producto producto) =>
    showDialog<void>(context: context, builder: (_) => _DialogoStock(producto: producto));

class _DialogoStock extends StatefulWidget {
  final Producto producto;
  const _DialogoStock({required this.producto});

  @override
  State<_DialogoStock> createState() => _DialogoStockState();
}

class _DialogoStockState extends State<_DialogoStock> {
  final _numero = TextEditingController();
  _Modo _modo = _Modo.entro;
  String? _error;

  String get _etiqueta => switch (_modo) {
        _Modo.entro => '¿Cuántas unidades llegaron?',
        _Modo.perdi => '¿Cuántas unidades se perdieron o regaló?',
        _Modo.conte => '¿Cuántas hay en total?',
      };

  Future<void> _guardar() async {
    final n = int.tryParse(_numero.text.trim());
    if (n == null || n < 0 || n > 1000000 || (_modo != _Modo.conte && n == 0)) {
      setState(() => _error = 'Escriba un número, por ejemplo 12.');
      return;
    }
    final inv = context.read<Inventario>();
    final id = widget.producto.id;
    switch (_modo) {
      case _Modo.entro:
        await inv.moverStock(id, n, MotivoInventario.compra);
      case _Modo.perdi:
        await inv.moverStock(id, -n, MotivoInventario.ajuste);
      case _Modo.conte:
        await inv.contarStock(id, n);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.producto.nombre),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            widget.producto.controlaStock ? 'Ahora tiene ${widget.producto.stock}' : 'Aún no lleva la cuenta de cantidad',
            style: const TextStyle(color: Colores.gris, fontSize: 14)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChipCaporal('Llegó mercancía', seleccionado: _modo == _Modo.entro, alTocar: () => setState(() => _modo = _Modo.entro)),
          ChipCaporal('Se perdió', seleccionado: _modo == _Modo.perdi, alTocar: () => setState(() => _modo = _Modo.perdi)),
          ChipCaporal('Conté', seleccionado: _modo == _Modo.conte, alTocar: () => setState(() => _modo = _Modo.conte)),
        ]),
        const SizedBox(height: 12),
        TextField(
            controller: _numero,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: _etiqueta)),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: Colores.rojo, fontSize: 14)),
          ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
