import 'package:flutter/material.dart';

import '../data/producto.dart';
import 'selector_productos.dart';
import 'tema.dart';

/// Lo que llegó en un pedido: productos con su cantidad y, si quiere, de quién.
/// Al guardar el gasto, esas unidades se suman al inventario.
class PanelPedido extends StatelessWidget {
  final List<LineaVenta> lineas;
  final TextEditingController proveedor;
  final ValueChanged<LineaVenta> alCambiar;
  final ValueChanged<Producto> alQuitar;
  const PanelPedido({
    super.key,
    required this.lineas,
    required this.proveedor,
    required this.alCambiar,
    required this.alQuitar,
  });

  Future<void> _elegir(BuildContext context, Producto p) async {
    final actual = lineas.where((l) => l.producto.id == p.id).map((l) => l.cantidad).firstOrNull;
    final n = await pedirCantidad(context, p, actual: actual);
    if (n != null) alCambiar(LineaVenta(p, n));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('¿Qué llegó? Toque cada producto y escriba cuántos.',
          style: TextStyle(fontSize: 13, color: Colores.gris)),
      const SizedBox(height: 6),
      SelectorProductos(enVenta: const [], modoPedido: true, alElegir: (p) => _elegir(context, p)),
      if (lineas.isNotEmpty) ...[
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final l in lineas)
            InputChip(
              label: Text('+${l.cantidad} ${l.producto.nombre}'),
              onPressed: () => _elegir(context, l.producto),
              onDeleted: () => alQuitar(l.producto),
              backgroundColor: Colores.verdeClaro,
              side: BorderSide.none,
            ),
        ]),
      ],
      const SizedBox(height: 6),
      TextField(
        controller: proveedor,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: '¿De quién? (opcional)', isDense: true),
      ),
    ]);
  }
}

/// "¿Cuántas llegaron de Galletas?" Devuelve la cantidad, o null si se canceló.
Future<int?> pedirCantidad(BuildContext context, Producto p, {int? actual}) {
  final c = TextEditingController(text: actual?.toString() ?? '');
  String? error;
  return showDialog<int>(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (d, setState) => AlertDialog(
        title: Text('¿Cuántas llegaron de ${p.nombre}?'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Unidades', errorText: error),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(c.text.trim());
              if (n == null || n <= 0 || n > 100000) {
                setState(() => error = 'Escriba un número, por ejemplo 24.');
                return;
              }
              Navigator.pop(d, n);
            },
            child: const Text('Listo'),
          ),
        ],
      ),
    ),
  );
}
