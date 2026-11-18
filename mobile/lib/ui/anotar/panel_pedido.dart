import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/formato.dart';
import '../../dominio/precios.dart';
import '../../dominio/producto.dart';
import '../../sincronizacion/sesion.dart';
import 'selector_productos.dart';
import '../comun/tema.dart';

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
    final actual = lineas.where((l) => l.producto.id == p.id).firstOrNull;
    final linea = await pedirLlegada(context, p, actual: actual, margen: context.read<Sesion>().margen);
    if (linea != null) alCambiar(linea);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('¿Qué llegó? Toque cada producto y escriba cuántos y a cuánto le costó.',
          style: TextStyle(fontSize: 13, color: Colores.gris)),
      const SizedBox(height: 6),
      SelectorProductos(enVenta: const [], modoPedido: true, alElegir: (p) => _elegir(context, p)),
      if (lineas.isNotEmpty) ...[
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final l in lineas)
            InputChip(
              label: Text('+${l.cantidad} ${l.producto.nombre}${l.costo == null ? '' : ' · ${pesos(l.costo!)} c/u'}'),
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

/// "¿Cuántas llegaron de Galletas y a cuánto le costó cada una?". Devuelve la línea del pedido
/// (con el costo y, si quiso, el precio nuevo), o null si se canceló.
Future<LineaVenta?> pedirLlegada(BuildContext context, Producto p, {LineaVenta? actual, required int margen}) {
  final cantidad = TextEditingController(text: actual?.cantidad.toString() ?? '');
  final costo = TextEditingController(text: (actual?.costo ?? p.costo)?.toString() ?? '');
  var subirPrecio = actual?.precioNuevo != null;
  String? error;
  return showDialog<LineaVenta>(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (d, setState) {
        final c = int.tryParse(costo.text.trim());
        final sugerido = c == null || c <= 0 ? null : Precios.sugerido(c, margen);
        final ganaMenos = c != null && c > 0 && Precios.ganaMenos(p.precio, c, margen);
        return AlertDialog(
          title: Text('Llegó ${p.nombre}'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: cantidad,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '¿Cuántas llegaron?'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: costo,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '¿Cuánto le costó cada una? (opcional)',
                  helperText: 'Si trae el total de la factura, divídalo por las unidades.',
                ),
              ),
              if (c != null && c > 0) ...[
                const SizedBox(height: 8),
                Text('Lo vende a ${pesos(p.precio)}: ${Precios.explicar(p.precio, c).toLowerCase()}.',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ganaMenos ? Colores.ambarTexto : Colores.verde)),
                if (ganaMenos && sugerido != null)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: subirPrecio,
                    onChanged: (v) => setState(() => subirPrecio = v ?? false),
                    title: Text('Subir el precio a ${pesos(sugerido)} para ganar $margen %',
                        style: const TextStyle(fontSize: 14)),
                  ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: Colores.rojo, fontSize: 13)),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final n = int.tryParse(cantidad.text.trim());
                if (n == null || n <= 0 || n > 100000) {
                  setState(() => error = 'Escriba cuántas llegaron, por ejemplo 24.');
                  return;
                }
                if (costo.text.trim().isNotEmpty && (c == null || c <= 0 || c > 99999999)) {
                  setState(() => error = 'El costo debe ser un número en pesos, por ejemplo 2000.');
                  return;
                }
                Navigator.pop(
                    d,
                    LineaVenta(p, n,
                        costo: (c != null && c > 0) ? c : null,
                        precioNuevo: (ganaMenos && subirPrecio) ? sugerido : null));
              },
              child: const Text('Listo'),
            ),
          ],
        );
      },
    ),
  );
}
