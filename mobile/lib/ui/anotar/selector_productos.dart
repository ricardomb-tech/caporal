import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/inventario.dart';
import '../../dominio/producto.dart';
import '../../dominio/formato.dart';
import '../inventario/dialogo_producto.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Fila de productos para vender con un toque, con lo que queda de cada uno y un "+ Nuevo".
class SelectorProductos extends StatelessWidget {
  /// Lo que ya se agregó a esta venta (un producto aparece tantas veces como unidades).
  final List<Producto> enVenta;
  final ValueChanged<Producto> alElegir;

  /// En un pedido se muestra cuánto tiene (para saber qué pedir) y no se descuenta lo elegido.
  final bool modoPedido;
  const SelectorProductos({super.key, required this.enVenta, required this.alElegir, this.modoPedido = false});

  Future<void> _nuevo(BuildContext context) async {
    final p = await mostrarDialogoProducto(context, conCantidadInicial: !modoPedido);
    if (p != null) alElegir(p);
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<Inventario>();
    return SizedBox(
      height: 74,
      child: FutureBuilder<List<Producto>>(
        future: inv.productos(),
        builder: (_, s) {
          final lista = s.data ?? const <Producto>[];
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: lista.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == lista.length) return _ChipNuevo(alTocar: () => _nuevo(context));
              final p = lista[i];
              final quedan = modoPedido ? p.stock : p.stock - enVenta.where((x) => x.id == p.id).length;
              return _ChipProducto(
                  producto: p, quedan: quedan, prefijo: modoPedido ? 'Tiene' : 'Quedan', alTocar: () => alElegir(p));
            },
          );
        },
      ),
    );
  }
}

class _ChipProducto extends StatelessWidget {
  final Producto producto;
  final int quedan;
  final String prefijo;
  final VoidCallback alTocar;
  const _ChipProducto({required this.producto, required this.quedan, required this.prefijo, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final String? aviso;
    final Color colorAviso;
    if (!producto.controlaStock) {
      aviso = null;
      colorAviso = Colores.gris;
    } else if (quedan <= 0) {
      aviso = 'Agotado';
      colorAviso = Colores.rojo;
    } else if (quedan <= Producto.umbralPocas) {
      aviso = '$prefijo $quedan';
      colorAviso = Colores.ambarTexto;
    } else {
      aviso = '$prefijo $quedan';
      colorAviso = Colores.gris;
    }
    return comoBoton(
      hijo: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: alTocar,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(producto.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(pesos(producto.precio), style: const TextStyle(fontSize: 12, color: Colores.gris)),
                  if (aviso != null)
                    Text(aviso, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorAviso)),
                ]),
          )),
    );
  }
}

class _ChipNuevo extends StatelessWidget {
  final VoidCallback alTocar;
  const _ChipNuevo({required this.alTocar});

  @override
  Widget build(BuildContext context) => comoBoton(
        etiqueta: 'Nuevo producto',
        hijo: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: alTocar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colores.verdeClaro,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colores.verde, width: 1.2),
              ),
              alignment: Alignment.center,
              child: const Row(children: [
                Icon(Icons.add, color: Colores.verde, size: 18),
                SizedBox(width: 4),
                Text('Nuevo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colores.verde)),
              ]),
            )),
      );
}
