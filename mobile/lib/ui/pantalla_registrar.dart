import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/movimiento.dart';
import '../data/producto.dart';
import '../data/repositorio.dart';
import '../formato.dart';
import 'panel_pedido.dart';
import 'pantalla_exito.dart';
import 'selector_productos.dart';
import 'tema.dart';
import 'widgets.dart';

/// Registro en tres toques: elegir qué pasó (desde el inicio), poner el valor y guardar.
class PantallaRegistrar extends StatefulWidget {
  final TipoMovimiento tipo;
  final String? clienteInicial;
  const PantallaRegistrar({super.key, required this.tipo, this.clienteInicial});

  @override
  State<PantallaRegistrar> createState() => _PantallaRegistrarState();
}

class _PantallaRegistrarState extends State<PantallaRegistrar> {
  static const _pedido = 'Pedido';
  static const _categorias = [
    _pedido,
    'Mercado',
    'Arriendo',
    'Servicios',
    'Transporte',
    'Otro'
  ];

  String _digitos = '';
  late final TextEditingController _cliente =
      TextEditingController(text: widget.clienteInicial ?? '');
  final _nota = TextEditingController();
  final List<Producto> _carrito = [];

  /// Lo que llegó en un pedido (gasto de mercancía), por producto.
  final Map<String, LineaVenta> _llegada = {};
  String _categoria = _categorias.first;
  String _medio = 'EFECTIVO';
  bool _guardando = false;

  /// Fiar es vender mercancía que se paga después (nunca un préstamo de dinero ni con intereses):
  /// por eso usa la misma pantalla de venta, con productos e inventario, y "Fiado" como forma de pago.
  late bool _fiado = widget.tipo == TipoMovimiento.fiado;

  int get _valor => _digitos.isEmpty ? 0 : int.parse(_digitos);
  TipoMovimiento get _tipo => _fiado ? TipoMovimiento.fiado : widget.tipo;
  bool get _esFiado => _tipo == TipoMovimiento.fiado;
  bool get _esGasto => _tipo == TipoMovimiento.gasto;
  bool get _esPedido => _esGasto && _categoria == _pedido;

  /// Venta de contado o fiada: se eligen productos y se descuentan del inventario.
  bool get _esVenta =>
      widget.tipo == TipoMovimiento.venta ||
      widget.tipo == TipoMovimiento.fiado;

  String get _titulo => switch (_tipo) {
        TipoMovimiento.venta => 'Vendí',
        TipoMovimiento.gasto => 'Gasté',
        TipoMovimiento.fiado => 'Vendí fiado',
        TipoMovimiento.abono => 'Me pagaron',
      };

  String get _subtitulo => switch (_tipo) {
        TipoMovimiento.venta => 'Toque un producto o escriba el valor',
        TipoMovimiento.gasto =>
          'Anote lo que pagó; si llegó mercancía, elija Pedido',
        TipoMovimiento.fiado => 'Lo que se lleva y quién lo paga después',
        TipoMovimiento.abono => 'Anote lo que le pagaron',
      };

  Color get _colorMonto =>
      _esGasto ? Colores.rojo : (_esFiado ? Colores.ambarTexto : Colores.verde);

  void _tecla(String t) {
    setState(() {
      if (t == 'Borrar') {
        if (_digitos.isNotEmpty) {
          _digitos = _digitos.substring(0, _digitos.length - 1);
        }
        if (_digitos.isEmpty) _carrito.clear();
      } else if (_digitos.length + t.length <= 9) {
        _digitos = (_digitos + t).replaceFirst(RegExp(r'^0+'), '');
      }
    });
  }

  void _sumarProducto(Producto p) {
    setState(() {
      _digitos = (_valor + p.precio).toString();
      _carrito.add(p);
    });
  }

  String? get _descripcion {
    if (_esGasto) {
      final partes = [
        _categoria,
        if (_esPedido && _llegada.isNotEmpty)
          _llegada.values
              .map((l) => '${l.cantidad} ${l.producto.nombre}')
              .join(', '),
        if (_nota.text.trim().isNotEmpty) _nota.text.trim(),
      ];
      return partes.join(' · ');
    }
    if (_carrito.isEmpty) return null;
    return _lineas
        .map((l) => l.cantidad > 1
            ? '${l.cantidad} ${l.producto.nombre}'
            : l.producto.nombre)
        .join(', ');
  }

  /// Lo vendido, agrupado por producto, en el orden en que se fue agregando.
  List<LineaVenta> get _lineas {
    final cuenta = <String, int>{};
    final productos = <String, Producto>{};
    for (final p in _carrito) {
      cuenta[p.id] = (cuenta[p.id] ?? 0) + 1;
      productos[p.id] = p;
    }
    return [
      for (final e in cuenta.entries) LineaVenta(productos[e.key]!, e.value)
    ];
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final m = await context.read<Repositorio>().registrar(
          tipo: _tipo,
          valor: _valor,
          descripcion: _descripcion,
          clienteNombre: (_esFiado || widget.tipo == TipoMovimiento.abono)
              ? _cliente.text.trim()
              : null,
          medioPago: _esFiado ? null : ((_esVenta || _esGasto) ? _medio : null),
          lineas: _esVenta
              ? _lineas
              : (_esPedido ? _llegada.values.toList() : const []),
        );
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => PantallaExito(movimiento: m)));
  }

  @override
  Widget build(BuildContext context) {
    final puedeGuardar = _valor > 0 &&
        !_guardando &&
        (!_esFiado || _cliente.text.trim().isNotEmpty);
    return Scaffold(
      // El teclado del sistema pasa por encima del teclado numérico (que no se usa mientras se escribe un nombre).
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(children: [
            Row(children: [
              const BotonAtras(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_titulo,
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.bold)),
                      Text(_subtitulo,
                          style: const TextStyle(
                              fontSize: 14, color: Colores.gris)),
                    ]),
              ),
            ]),
            // Lo de arriba se desplaza si no cabe; el teclado numérico siempre conserva su tamaño.
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  const SizedBox(height: 12),
                  if (_esVenta)
                    SelectorProductos(
                        enVenta: _carrito, alElegir: _sumarProducto),
                  if (_esGasto)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final c in _categorias)
                          ChipCaporal(c,
                              seleccionado: c == _categoria,
                              alTocar: () => setState(() => _categoria = c)),
                      ]),
                    ),
                  if (_esPedido) ...[
                    const SizedBox(height: 8),
                    PanelPedido(
                      lineas: _llegada.values.toList(),
                      proveedor: _nota,
                      alCambiar: (l) =>
                          setState(() => _llegada[l.producto.id] = l),
                      alQuitar: (p) => setState(() => _llegada.remove(p.id)),
                    ),
                  ],
                  if (_esFiado || widget.tipo == TipoMovimiento.abono)
                    TextField(
                      controller: _cliente,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                          labelText: _esFiado
                              ? '¿A quién le fió?'
                              : '¿Quién le pagó?'),
                    ),
                ]),
              ),
            ),
            // El valor y la forma de pago quedan siempre a la vista, junto al teclado.
            const SizedBox(height: 10),
            Tarjeta(
              relleno: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              hijo: Column(children: [
                if (_descripcion != null && !_esGasto)
                  Text(_descripcion!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 14, color: Colores.gris)),
                Text(pesos(_valor),
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: _colorMonto)),
              ]),
            ),
            const SizedBox(height: 8),
            if (_esVenta || _esGasto)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(spacing: 8, children: [
                  ChipCaporal('Efectivo',
                      seleccionado: !_esFiado && _medio == 'EFECTIVO',
                      alTocar: () => setState(() {
                            _medio = 'EFECTIVO';
                            _fiado = false;
                          })),
                  ChipCaporal('Bre-B',
                      seleccionado: !_esFiado && _medio == 'BREB',
                      alTocar: () => setState(() {
                            _medio = 'BREB';
                            _fiado = false;
                          })),
                  if (_esVenta)
                    ChipCaporal('Fiado',
                        seleccionado: _esFiado,
                        alTocar: () => setState(() => _fiado = true)),
                ]),
              ),
            const SizedBox(height: 6),
            SizedBox(
              height: 232,
              child: Column(children: [
                for (final fila in const [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                  ['000', '0', 'Borrar'],
                ])
                  Expanded(
                    child: Row(children: [
                      for (final t in fila)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _tecla(t),
                                child: Center(
                                  child: Text(t,
                                      style: TextStyle(
                                          fontSize: t == 'Borrar' ? 16 : 26,
                                          fontWeight: FontWeight.w600,
                                          color: t == 'Borrar'
                                              ? Colores.rojo
                                              : Colores.texto)),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            BotonCaporal(
                _esGasto
                    ? 'Guardar gasto'
                    : (_esFiado ? 'Anotar deuda' : 'Guardar'),
                icono: Icons.check,
                alTocar: puedeGuardar ? _guardar : null),
          ]),
        ),
      ),
    );
  }
}
