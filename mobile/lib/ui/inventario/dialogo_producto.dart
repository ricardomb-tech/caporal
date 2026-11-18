import 'package:flutter/material.dart';
import '../comun/negocio_actual.dart';
import 'package:provider/provider.dart';

import '../../datos/inventario.dart';
import '../../dominio/categorias.dart';
import '../../dominio/formato.dart';
import '../../dominio/precios.dart';
import '../../dominio/producto.dart';
import '../../sincronizacion/sesion.dart';
import '../comun/tema.dart';
import 'pantalla_nuevo_producto.dart';

/// Crear o editar un producto. Devuelve el producto guardado, o null si se canceló o se quitó.
/// [conCantidadInicial] en false cuando la cantidad la pone otra anotación (por ejemplo, un pedido que llegó).
/// Crear abre el formulario guiado paso a paso; editar abre un diálogo corto.
Future<Producto?> mostrarDialogoProducto(BuildContext context, {Producto? producto, bool conCantidadInicial = true}) {
  if (producto == null) {
    return Navigator.push<Producto>(
        context, MaterialPageRoute(builder: (_) => PantallaNuevoProducto(conCantidadInicial: conCantidadInicial)));
  }
  return showDialog<Producto>(
      context: context, builder: (_) => _DialogoProducto(producto: producto, conCantidadInicial: conCantidadInicial));
}

class _DialogoProducto extends StatefulWidget {
  final Producto? producto;
  final bool conCantidadInicial;
  const _DialogoProducto({this.producto, this.conCantidadInicial = true});

  @override
  State<_DialogoProducto> createState() => _DialogoProductoState();
}

class _DialogoProductoState extends State<_DialogoProducto> {
  late final _nombre = TextEditingController(text: widget.producto?.nombre ?? '');
  late final _precio = TextEditingController(text: widget.producto?.precio.toString() ?? '');
  late final _costo = TextEditingController(text: widget.producto?.costo?.toString() ?? '');
  final _cantidad = TextEditingController();
  late bool _llevaCuenta = widget.producto?.controlaStock ?? true;
  late String? _categoria = widget.producto?.categoria;
  bool _guardando = false;
  String? _error;

  bool get _nuevo => widget.producto == null;

  /// Valida y devuelve el mensaje de error, o null si todo está bien.
  Future<String?> _validar(Inventario inv) async {
    final nombre = _nombre.text.trim();
    final precio = int.tryParse(_precio.text.trim());
    if (nombre.isEmpty) return 'Escriba el nombre del producto.';
    if (nombre.length > 60) return 'El nombre es muy largo (máximo 60 letras).';
    if (precio == null || precio < 1) return 'Escriba el precio en pesos, por ejemplo 3000.';
    if (precio > 99999999) return 'Ese precio es muy alto. Revíselo.';
    if (_costo.text.trim().isNotEmpty) {
      final c = int.tryParse(_costo.text.trim());
      if (c == null || c < 0 || c > 99999999) return 'El costo debe ser un número en pesos, por ejemplo 2000.';
    }
    if (_nuevo && _llevaCuenta && _cantidad.text.trim().isNotEmpty) {
      final c = int.tryParse(_cantidad.text.trim());
      if (c == null || c < 0 || c > 1000000) return 'La cantidad debe ser un número, por ejemplo 12.';
    }
    final repetido = (await inv.productos())
        .any((p) => p.id != widget.producto?.id && p.nombre.toLowerCase() == nombre.toLowerCase());
    if (repetido) return 'Ya tiene un producto con ese nombre.';
    return null;
  }

  Future<void> _guardar() async {
    final inv = context.read<Inventario>();
    setState(() => _guardando = true);
    final error = await _validar(inv);
    if (error != null) {
      setState(() {
        _error = error;
        _guardando = false;
      });
      return;
    }
    final nombre = _nombre.text.trim();
    final precio = int.parse(_precio.text.trim());
    final costo = int.tryParse(_costo.text.trim());
    final Producto resultado;
    if (_nuevo) {
      final cantidad = _llevaCuenta ? (int.tryParse(_cantidad.text.trim()) ?? 0) : null;
      resultado = await inv.crearProducto(
          nombre: nombre, precio: precio, stockInicial: cantidad, costo: costo, categoria: _categoria);
    } else {
      await inv.editarProducto(widget.producto!.id,
          nombre: nombre, precio: precio, controlaStock: _llevaCuenta, costo: costo, categoria: _categoria);
      resultado = (await inv.producto(widget.producto!.id))!;
    }
    if (mounted) Navigator.pop(context, resultado);
  }

  Future<void> _quitar() async {
    await context.read<Inventario>().quitarProducto(widget.producto!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_nuevo ? 'Nuevo producto' : 'Editar producto'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _categoria,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: [
              for (final c in Categorias.para(negocioActual(context).nombre, actual: widget.producto?.categoria))
                DropdownMenuItem(value: c, child: Text(c))
            ],
            onChanged: (c) => setState(() => _categoria = c),
          ),
          const SizedBox(height: 10),
          TextField(
              controller: _costo,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: '¿A cuánto lo compra? (opcional)')),
          const SizedBox(height: 10),
          TextField(
              controller: _precio,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: '¿A cuánto lo vende?')),
          _InfoGanancia(costo: int.tryParse(_costo.text.trim()), precio: int.tryParse(_precio.text.trim())),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Llevar la cuenta de cuántos tengo', style: TextStyle(fontSize: 14)),
            value: _llevaCuenta,
            onChanged: (v) => setState(() => _llevaCuenta = v),
          ),
          if (_nuevo && _llevaCuenta && widget.conCantidadInicial)
            TextField(
                controller: _cantidad,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '¿Cuántos tiene ahora?')),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: const TextStyle(color: Colores.rojo, fontSize: 14)),
            ),
        ]),
      ),
      actions: [
        if (!_nuevo) TextButton(onPressed: _quitar, child: const Text('Quitar', style: TextStyle(color: Colores.rojo))),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardando ? null : _guardar, child: const Text('Guardar')),
      ],
    );
  }
}

/// "Gana $ 500 por cada una (25 %)" mientras escribe, y el precio sugerido si gana menos de lo elegido.
class _InfoGanancia extends StatelessWidget {
  final int? costo;
  final int? precio;
  const _InfoGanancia({required this.costo, required this.precio});

  @override
  Widget build(BuildContext context) {
    final c = costo, p = precio;
    if (c == null || c <= 0 || p == null || p <= 0) return const SizedBox.shrink();
    final margen = context.read<Sesion>().margen;
    final menos = Precios.ganaMenos(p, c, margen);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        menos
            ? '${Precios.explicar(p, c)}. Para ganar $margen %: ${pesos(Precios.sugerido(c, margen))}.'
            : Precios.explicar(p, c),
        style: TextStyle(fontSize: 13, color: menos ? Colores.ambarTexto : Colores.verde, fontWeight: FontWeight.w600),
      ),
    );
  }
}
