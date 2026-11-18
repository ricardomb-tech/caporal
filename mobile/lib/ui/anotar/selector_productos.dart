import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/inventario.dart';
import '../../dominio/categorias.dart';
import '../../dominio/producto.dart';
import '../../dominio/formato.dart';
import '../inventario/dialogo_producto.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Productos para vender con un toque, con lo que queda de cada uno y un "+ Nuevo".
/// Arriba, un buscador (sin importar tildes ni mayúsculas) y las categorías que tengan productos.
class SelectorProductos extends StatefulWidget {
  /// Lo que ya se agregó a esta venta (un producto aparece tantas veces como unidades).
  final List<Producto> enVenta;
  final ValueChanged<Producto> alElegir;

  /// En un pedido se muestra cuánto tiene (para saber qué pedir) y no se descuenta lo elegido.
  final bool modoPedido;
  const SelectorProductos({super.key, required this.enVenta, required this.alElegir, this.modoPedido = false});

  @override
  State<SelectorProductos> createState() => _SelectorProductosState();
}

class _SelectorProductosState extends State<SelectorProductos> {
  /// El buscador aparece en cuanto hay productos.
  static const _paraBuscar = 1;

  final _busqueda = TextEditingController();
  String? _categoria;

  // Los productos se leen de la base solo cuando cambian; al escribir se filtra en memoria.
  late final Inventario _inventario = context.read<Inventario>();
  late Future<List<Producto>> _productos = _inventario.productos();

  void _recargar() {
    if (!mounted) return;
    setState(() {
      _productos = _inventario.productos();
    });
  }

  @override
  void initState() {
    super.initState();
    _inventario.addListener(_recargar);
  }

  @override
  void dispose() {
    _inventario.removeListener(_recargar);
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _nuevo(BuildContext context) async {
    final p = await mostrarDialogoProducto(context, conCantidadInicial: !widget.modoPedido);
    if (p != null) widget.alElegir(p);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Producto>>(
      future: _productos,
      builder: (_, s) {
        final todos = s.data ?? const <Producto>[];
        final categorias = [
          for (final c in Categorias.todas)
            if (todos.any((p) => p.categoria == c)) c
        ];
        final lista = [
          for (final p in todos)
            if (Categorias.coincide(p, busqueda: _busqueda.text, categoria: _categoria)) p,
        ];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (todos.length >= _paraBuscar) ...[
            TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar producto',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _busqueda.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Borrar búsqueda',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(_busqueda.clear),
                      ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (categorias.isNotEmpty) ...[
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                ChipCaporal('Todos',
                    seleccionado: _categoria == null, alTocar: () => setState(() => _categoria = null)),
                for (final c in categorias) ...[
                  const SizedBox(width: 6),
                  ChipCaporal(c, seleccionado: _categoria == c, alTocar: () => setState(() => _categoria = c)),
                ],
              ]),
            ),
            const SizedBox(height: 6),
          ],
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lista.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == lista.length) return _ChipNuevo(alTocar: () => _nuevo(context));
                final p = lista[i];
                final quedan = widget.modoPedido ? p.stock : p.stock - widget.enVenta.where((x) => x.id == p.id).length;
                return _ChipProducto(
                    producto: p,
                    quedan: quedan,
                    prefijo: widget.modoPedido ? 'Tiene' : 'Quedan',
                    alTocar: () => widget.alElegir(p));
              },
            ),
          ),
          if (lista.isEmpty && todos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                  _busqueda.text.trim().isEmpty
                      ? 'No hay productos en esta categoría. Si es nuevo, créelo con "+ Nuevo".'
                      : 'No hay productos con "${_busqueda.text.trim()}". Si es nuevo, créelo con "+ Nuevo".',
                  style: const TextStyle(fontSize: 13, color: Colores.gris)),
            ),
        ]);
      },
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
