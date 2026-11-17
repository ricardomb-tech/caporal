import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/inventario.dart';
import '../data/producto.dart';
import '../formato.dart';
import 'dialogo_producto.dart';
import 'dialogo_stock.dart';
import 'tema.dart';
import 'widgets.dart';

/// Un producto: cuánto hay, sus acciones y todo lo que le ha pasado.
class PantallaProducto extends StatelessWidget {
  final String productoId;
  const PantallaProducto({super.key, required this.productoId});

  static String _cuando(DateTime t) {
    final l = t.toLocal();
    final hoy = DateTime.now();
    final hora = '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    if (l.year == hoy.year && l.month == hoy.month && l.day == hoy.day) return 'Hoy $hora';
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')} $hora';
  }

  static String _motivo(MovInventario m) => switch (m.motivo) {
        MotivoInventario.inicial => 'Cantidad inicial',
        MotivoInventario.compra => 'Llegó mercancía',
        MotivoInventario.venta => 'Venta',
        MotivoInventario.ajuste => m.delta < 0 ? 'Se perdió o se ajustó' : 'Ajuste al contar',
        MotivoInventario.reverso => 'Venta corregida',
      };

  Future<(Producto?, List<MovInventario>)> _cargar(Inventario inv) async =>
      (await inv.producto(productoId), await inv.historial(productoId));

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<Inventario>();
    return FutureBuilder<(Producto?, List<MovInventario>)>(
      future: _cargar(inv),
      builder: (_, s) {
        final p = s.data?.$1;
        final historial = s.data?.$2 ?? const <MovInventario>[];
        if (p == null || !p.activo) {
          return const Pantalla(titulo: 'Producto', hijos: [Tarjeta(hijo: Text('Este producto ya no está en su lista.'))]);
        }
        return Pantalla(
          titulo: p.nombre,
          subtitulo: pesos(p.precio),
          hijos: [
            Tarjeta(
              hijo: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Tiene', style: TextStyle(color: Colores.gris, fontSize: 14)),
                    Text(p.controlaStock ? '${p.stock}' : '—',
                        style: TextStyle(
                            fontSize: 38, fontWeight: FontWeight.bold, color: p.agotado ? Colores.rojo : Colores.texto)),
                    if (p.agotado) const Text('Agotado', style: TextStyle(color: Colores.rojo, fontWeight: FontWeight.w600)),
                    if (p.pocas) const Text('Se está acabando', style: TextStyle(color: Colores.ambarTexto, fontWeight: FontWeight.w600)),
                    if (!p.controlaStock)
                      const Text('No lleva la cuenta de cantidad', style: TextStyle(color: Colores.gris, fontSize: 13)),
                  ]),
                ),
                if (p.controlaStock) Text(pesos(p.stock * p.precio), style: const TextStyle(fontSize: 16, color: Colores.gris)),
              ]),
            ),
            Row(children: [
              Expanded(
                  child: BotonCaporal('Anotar cantidad',
                      icono: Icons.inventory_2_outlined, alTocar: () => mostrarDialogoStock(context, p))),
              const SizedBox(width: 10),
              Expanded(
                  child: BotonCaporal('Editar',
                      estilo: EstiloBoton.contorno, icono: Icons.edit_outlined, alTocar: () => mostrarDialogoProducto(context, producto: p))),
            ]),
            if (historial.isNotEmpty)
              Tarjeta(
                relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                hijo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 4),
                    child: Text('Historial', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.gris)),
                  ),
                  for (final (i, m) in historial.indexed) ...[
                    if (i > 0) lineaSuave,
                    FilaLista(
                      inicio: Insignia.icono(m.delta > 0 ? Icons.add : Icons.remove,
                          m.delta > 0 ? Colores.verde : Colores.rojo,
                          fondo: m.delta > 0 ? Colores.verdeClaro : Colores.rojoClaro),
                      titulo: _motivo(m),
                      detalle: _cuando(m.creadoEn),
                      fin: Text('${m.delta > 0 ? '+' : ''}${m.delta}',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold, color: m.delta > 0 ? Colores.verde : Colores.rojo)),
                    ),
                  ],
                ]),
              ),
          ],
        );
      },
    );
  }
}
