import 'package:flutter/material.dart';

import '../../dominio/producto.dart';
import '../../dominio/formato.dart';
import '../comun/tema.dart';

/// Lo que lleva el cliente: un renglón por producto con su cantidad, − / + y subtotal.
/// El total de la venta se va sumando solo.
class ListaVenta extends StatelessWidget {
  final List<LineaVenta> lineas;
  final ValueChanged<Producto> alSumar;
  final ValueChanged<Producto> alRestar;
  const ListaVenta(
      {super.key,
      required this.lineas,
      required this.alSumar,
      required this.alRestar});

  @override
  Widget build(BuildContext context) {
    final total =
        lineas.fold<int>(0, (a, l) => a + l.cantidad * l.producto.precio);
    final unidades = lineas.fold<int>(0, (a, l) => a + l.cantidad);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        for (final l in lineas)
          Row(children: [
            Expanded(
              child: Text(l.producto.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            _Boton(Icons.remove, 'Quitar uno de ${l.producto.nombre}',
                () => alRestar(l.producto)),
            SizedBox(
              width: 28,
              child: Text('${l.cantidad}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            _Boton(Icons.add, 'Agregar otro ${l.producto.nombre}',
                () => alSumar(l.producto)),
            SizedBox(
              width: 84,
              child: Text(pesos(l.cantidad * l.producto.precio),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14, color: Colores.gris)),
            ),
          ]),
        const Divider(height: 12, color: Color(0xFFE4E7E2)),
        Row(children: [
          Expanded(
            child: Text('$unidades ${unidades == 1 ? 'producto' : 'productos'}',
                style: const TextStyle(fontSize: 13, color: Colores.gris)),
          ),
          Text('Total ${pesos(total)}',
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}

class _Boton extends StatelessWidget {
  final IconData icono;
  final String descripcion;
  final VoidCallback alTocar;
  const _Boton(this.icono, this.descripcion, this.alTocar);

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: descripcion,
        onPressed: alTocar,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
            backgroundColor: Colores.verdeClaro,
            foregroundColor: Colores.verde),
        icon: Icon(icono, size: 18),
      );
}
