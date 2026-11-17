import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/inventario.dart';
import '../data/producto.dart';
import '../formato.dart';
import 'dialogo_producto.dart';
import 'pantalla_producto.dart';
import 'tema.dart';
import 'widgets.dart';

/// Donde la tienda ve todo su inventario: cuánto tiene de cada producto, qué se agotó y cuánto vale.
class PantallaInventario extends StatelessWidget {
  const PantallaInventario({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<Inventario>();
    return FutureBuilder<List<Producto>>(
      future: inv.productos(),
      builder: (_, s) {
        final lista = s.data ?? const <Producto>[];
        return Pantalla(
          titulo: 'Mi inventario',
          subtitulo: 'Lo que tiene y lo que se vende',
          hijos: [
            if (lista.isNotEmpty) const _ResumenInventario(),
            if (lista.isEmpty)
              const Tarjeta(
                  hijo: Text('Aún no tiene productos. Agregue los que más vende: así la app le dice cuánto le queda y anota con un toque.',
                      style: TextStyle(fontSize: 15, color: Colores.gris)))
            else
              Tarjeta(
                relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                hijo: Column(children: [
                  for (final (i, p) in lista.indexed) ...[
                    if (i > 0) lineaSuave,
                    FilaLista(
                      inicio: Insignia.letra(p.nombre[0].toUpperCase(), Colores.verde, Colores.verdeClaro),
                      titulo: p.nombre,
                      detalle: pesos(p.precio),
                      fin: _EtiquetaCantidad(p),
                      alTocar: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => PantallaProducto(productoId: p.id))),
                    ),
                  ],
                ]),
              ),
            const Text('Toque un producto para ver su historial, anotar mercancía o cambiar su precio.',
                style: TextStyle(fontSize: 13, color: Colores.gris)),
          ],
          pie: BotonCaporal('Agregar producto', icono: Icons.add, alTocar: () => mostrarDialogoProducto(context)),
        );
      },
    );
  }
}

class _ResumenInventario extends StatelessWidget {
  const _ResumenInventario();

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<Inventario>();
    return FutureBuilder<ResumenInventario>(
      future: inv.resumen(),
      builder: (_, s) {
        final r = s.data ?? const ResumenInventario(0, 0, 0, 0);
        return Tarjeta(
          color: Colores.verde,
          relleno: const EdgeInsets.all(20),
          hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Lo que tiene guardado', style: TextStyle(color: Colors.white70, fontSize: 15)),
            Text(pesos(r.valor), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            Text('${r.unidades} unidades en ${r.productos} ${r.productos == 1 ? 'producto' : 'productos'}',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            if (r.agotados > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colores.rojoClaro, borderRadius: BorderRadius.circular(14)),
                child: Text('${r.agotados} ${r.agotados == 1 ? 'producto agotado' : 'productos agotados'}',
                    style: const TextStyle(color: Colores.rojo, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
        );
      },
    );
  }
}

/// Cantidad de un producto, con el color de su estado.
class _EtiquetaCantidad extends StatelessWidget {
  final Producto p;
  const _EtiquetaCantidad(this.p);

  @override
  Widget build(BuildContext context) {
    final String texto;
    final Color color, fondo;
    if (!p.controlaStock) {
      texto = 'Sin cuenta';
      color = Colores.gris;
      fondo = const Color(0xFFEDEEEB);
    } else if (p.agotado) {
      texto = 'Agotado';
      color = Colores.rojo;
      fondo = Colores.rojoClaro;
    } else if (p.pocas) {
      texto = '${p.stock} · se acaba';
      color = Colores.ambarTexto;
      fondo = Colores.ambarClaro;
    } else {
      texto = '${p.stock}';
      color = Colores.verde;
      fondo = Colores.verdeClaro;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(14)),
      child: Text(texto, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
