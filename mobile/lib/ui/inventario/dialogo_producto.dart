import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/inventario.dart';
import '../../dominio/producto.dart';
import 'pantalla_nuevo_producto.dart';
import '../comun/tema.dart';

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
  final _cantidad = TextEditingController();
  late bool _llevaCuenta = widget.producto?.controlaStock ?? true;
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
    if (_nuevo && _llevaCuenta && _cantidad.text.trim().isNotEmpty) {
      final c = int.tryParse(_cantidad.text.trim());
      if (c == null || c < 0 || c > 1000000) return 'La cantidad debe ser un número, por ejemplo 12.';
    }
    final repetido = (await inv.productos()).any(
        (p) => p.id != widget.producto?.id && p.nombre.toLowerCase() == nombre.toLowerCase());
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
    final Producto resultado;
    if (_nuevo) {
      final cantidad = _llevaCuenta ? (int.tryParse(_cantidad.text.trim()) ?? 0) : null;
      resultado = await inv.crearProducto(nombre: nombre, precio: precio, stockInicial: cantidad);
    } else {
      await inv.editarProducto(widget.producto!.id, nombre: nombre, precio: precio, controlaStock: _llevaCuenta);
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
          TextField(
              controller: _precio,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio en pesos')),
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
        if (!_nuevo)
          TextButton(onPressed: _quitar, child: const Text('Quitar', style: TextStyle(color: Colores.rojo))),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardando ? null : _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
