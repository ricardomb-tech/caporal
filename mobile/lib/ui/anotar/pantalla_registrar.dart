import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/movimiento.dart';
import '../../dominio/producto.dart';
import '../../datos/clientes.dart';
import '../../datos/inventario.dart';
import '../../datos/repositorio.dart';
import '../../dominio/formato.dart';
import '../../dominio/tipos_de_negocio.dart';
import '../comun/negocio_actual.dart';
import 'panel_pedido.dart';
import 'lista_venta.dart';
import 'pantalla_exito.dart';
import 'selector_productos.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

/// Registro en tres toques: elegir qué pasó (desde el inicio), poner el valor y guardar.
class PantallaRegistrar extends StatefulWidget {
  final TipoMovimiento tipo;
  final String? clienteInicial;

  /// Movimiento que se está corrigiendo: la pantalla abre con sus datos (valor, productos, cliente,
  /// forma de pago) para cambiar solo lo que estaba mal.
  final Movimiento? corrigiendo;

  /// Valor con que abre (por ejemplo, lo que se le debe a un proveedor al ir a pagarle).
  final int? valorInicial;
  const PantallaRegistrar({super.key, required this.tipo, this.clienteInicial, this.corrigiendo, this.valorInicial});

  @override
  State<PantallaRegistrar> createState() => _PantallaRegistrarState();
}

class _PantallaRegistrarState extends State<PantallaRegistrar> {
  static const _pedido = TiposDeNegocio.pedido;

  /// Gastos que más anota este tipo de negocio, con "Pedido" primero.
  late final List<String> _categorias = TiposDeNegocio.gastosDe(negocioActual(context).nombre);

  late String _digitos = widget.valorInicial?.toString() ?? '';
  late final TextEditingController _cliente =
      TextEditingController(text: widget.corrigiendo?.clienteNombre ?? widget.clienteInicial ?? '');
  // Celular del cliente al fiar (opcional): solo se guarda si el cliente lo autoriza (Ley 1581).
  final _celularCliente = TextEditingController();
  bool _clienteAutoriza = false;
  String? _errorCelular;
  final _nota = TextEditingController();

  /// Proveedor de un pedido (o a quién se le pagó). Al fiarle el pedido, es obligatorio.
  late final _proveedor = TextEditingController(
      text:
          widget.tipo == TipoMovimiento.pago ? (widget.corrigiendo?.clienteNombre ?? widget.clienteInicial ?? '') : '');

  /// El proveedor dejó el pedido para pagárselo después.
  late bool _meFiaron = widget.tipo == TipoMovimiento.compra;
  final List<Producto> _carrito = [];

  /// Lo que llegó en un pedido (gasto de mercancía), por producto.
  final Map<String, LineaVenta> _llegada = {};
  late String _categoria = _categorias.first;
  String _medio = 'EFECTIVO';
  bool _guardando = false;

  /// Fiar es vender mercancía que se paga después (nunca un préstamo de dinero ni con intereses):
  /// por eso usa la misma pantalla de venta, con productos e inventario, y "Fiado" como forma de pago.
  late bool _fiado = widget.tipo == TipoMovimiento.fiado;

  @override
  void initState() {
    super.initState();
    final m = widget.corrigiendo;
    if (m != null) _cargarParaCorregir(m);
  }

  /// Vuelve a poner lo que tenía el movimiento original.
  Future<void> _cargarParaCorregir(Movimiento m) async {
    _digitos = m.valor.toString();
    if (m.medioPago != null) _medio = m.medioPago!;
    final partes = (m.descripcion ?? '').split(' · ');
    if (_esGasto && TiposDeNegocio.todasLasDeGasto.contains(partes.first)) {
      _categoria = partes.first;
      // Si el negocio cambió de tipo, la categoría del gasto original se sigue ofreciendo.
      if (!_categorias.contains(_categoria)) _categorias.insert(_categorias.length - 1, _categoria);
      final nota = partes.length > 1 && partes.first != _pedido ? partes.sublist(1).join(' · ') : '';
      _nota.text = nota;
    }
    if (_esGasto && m.clienteNombre != null) _proveedor.text = m.clienteNombre!;
    final lineas = await context.read<Inventario>().lineasDe(m.id);
    if (!mounted) return;
    setState(() {
      if (_esPedido) {
        for (final l in lineas) {
          _llegada[l.producto.id] = l;
        }
      } else if (_esVenta) {
        for (final l in lineas) {
          _carrito.addAll(List.filled(l.cantidad, l.producto));
        }
      }
    });
  }

  int get _valor => _digitos.isEmpty ? 0 : int.parse(_digitos);
  TipoMovimiento get _tipo {
    if (_fiado) return TipoMovimiento.fiado;
    if (_esGasto) return _esPedido && _meFiaron ? TipoMovimiento.compra : TipoMovimiento.gasto;
    return widget.tipo;
  }

  bool get _esFiado => _tipo == TipoMovimiento.fiado;

  /// Pantalla de gasto: un gasto o un pedido (pagado o fiado por el proveedor).
  bool get _esGasto => widget.tipo == TipoMovimiento.gasto || widget.tipo == TipoMovimiento.compra;
  bool get _esPedido => _esGasto && _categoria == _pedido;
  bool get _esCompraFiada => _tipo == TipoMovimiento.compra;
  bool get _esPagoProveedor => widget.tipo == TipoMovimiento.pago;

  /// El proveedor que se escribió (o null si se dejó vacío).
  String? get _nombreProveedor => _proveedor.text.trim().isEmpty ? null : _proveedor.text.trim();

  /// Venta de contado o fiada: se eligen productos y se descuentan del inventario.
  bool get _esVenta => widget.tipo == TipoMovimiento.venta || widget.tipo == TipoMovimiento.fiado;

  String get _titulo => switch (_tipo) {
        TipoMovimiento.venta => 'Vendí',
        TipoMovimiento.gasto => 'Gasté',
        TipoMovimiento.fiado => 'Vendí fiado',
        TipoMovimiento.abono => 'Me pagaron',
        TipoMovimiento.compra => 'Pedido fiado',
        TipoMovimiento.pago => 'Le pagué a un proveedor',
      };

  String get _subtitulo => widget.corrigiendo != null
      ? 'Cambie lo que estaba mal y guarde'
      : switch (_tipo) {
          TipoMovimiento.venta => 'Toque un producto o escriba el valor',
          TipoMovimiento.gasto => 'Anote lo que pagó; si llegó mercancía, elija Pedido',
          TipoMovimiento.fiado => 'Lo que se lleva y quién lo paga después',
          TipoMovimiento.abono => 'Anote lo que le pagaron',
          TipoMovimiento.compra => 'Lo que llegó y a quién se lo debe',
          TipoMovimiento.pago => 'Anote cuánto le pagó',
        };

  Color get _colorMonto => (_esFiado || _esCompraFiada)
      ? Colores.ambarTexto
      : ((_esGasto || _esPagoProveedor) ? Colores.rojo : Colores.verde);

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

  /// Quita una unidad del producto y descuenta su precio del total.
  void _restarProducto(Producto p) {
    setState(() {
      final i = _carrito.lastIndexWhere((x) => x.id == p.id);
      if (i < 0) return;
      _carrito.removeAt(i);
      final nuevo = _valor - p.precio;
      _digitos = (_carrito.isEmpty || nuevo <= 0) ? '' : nuevo.toString();
    });
  }

  String? get _descripcion {
    if (_esGasto) {
      final partes = [
        _categoria,
        if (_esPedido && _llegada.isNotEmpty)
          _llegada.values.map((l) => '${l.cantidad} ${l.producto.nombre}').join(', '),
        // En un pedido, el proveedor va aparte (como la otra persona del movimiento).
        if (!_esPedido && _nota.text.trim().isNotEmpty) _nota.text.trim(),
      ];
      return partes.join(' · ');
    }
    if (_carrito.isEmpty) return null;
    return _lineas.map((l) => l.cantidad > 1 ? '${l.cantidad} ${l.producto.nombre}' : l.producto.nombre).join(', ');
  }

  /// Lo vendido, agrupado por producto, en el orden en que se fue agregando.
  List<LineaVenta> get _lineas {
    final cuenta = <String, int>{};
    final productos = <String, Producto>{};
    for (final p in _carrito) {
      cuenta[p.id] = (cuenta[p.id] ?? 0) + 1;
      productos[p.id] = p;
    }
    return [for (final e in cuenta.entries) LineaVenta(productos[e.key]!, e.value)];
  }

  /// Revisa el celular escrito al fiar. Devuelve el número limpio (o null si no escribió) y
  /// deja el mensaje de error si no se puede guardar.
  String? _celularParaGuardar() {
    final escrito = _celularCliente.text.replaceAll(RegExp(r'[\s-]'), '');
    if (!_esFiado || escrito.isEmpty) return null;
    if (!Clientes.celularValido.hasMatch(escrito)) {
      _errorCelular = 'El celular debe tener 10 números y empezar por 3.';
    } else if (!_clienteAutoriza) {
      _errorCelular = 'Marque que ${_cliente.text.trim()} aceptó que guarde su número, o deje el celular vacío.';
    } else {
      _errorCelular = null;
    }
    return escrito;
  }

  Future<void> _guardar() async {
    final celular = _celularParaGuardar();
    if (_errorCelular != null) {
      setState(() {});
      return;
    }
    final clientes = context.read<Clientes>();
    setState(() => _guardando = true);
    final m = await context.read<Repositorio>().registrar(
          tipo: _tipo,
          valor: _valor,
          descripcion: _descripcion,
          clienteNombre: (_esFiado || widget.tipo == TipoMovimiento.abono)
              ? _cliente.text.trim()
              : ((_esPedido || _esPagoProveedor) ? _nombreProveedor : null),
          medioPago: (_esFiado || _esCompraFiada) ? null : ((_esVenta || _esGasto || _esPagoProveedor) ? _medio : null),
          lineas: _esVenta ? _lineas : (_esPedido ? _llegada.values.toList() : const []),
        );
    if (celular != null) await clientes.guardarCelular(_cliente.text.trim(), celular, autorizado: true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PantallaExito(movimiento: m)));
  }

  @override
  Widget build(BuildContext context) {
    final puedeGuardar = _valor > 0 &&
        !_guardando &&
        (!_esFiado || _cliente.text.trim().isNotEmpty) &&
        // A quién se le debe o se le pagó tiene que quedar claro.
        (!(_esCompraFiada || _esPagoProveedor) || _nombreProveedor != null);
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_titulo, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text(_subtitulo, style: const TextStyle(fontSize: 14, color: Colores.gris)),
                ]),
              ),
            ]),
            // Lo de arriba se desplaza si no cabe; el teclado numérico siempre conserva su tamaño.
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  const SizedBox(height: 12),
                  if (_esVenta) SelectorProductos(enVenta: _carrito, alElegir: _sumarProducto),
                  if (_esVenta && _carrito.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Toque cada producto que lleva: cada toque suma uno. Si no está, use "+ Nuevo".',
                          style: TextStyle(fontSize: 13, color: Colores.gris)),
                    ),
                  if (_esVenta && _carrito.isNotEmpty)
                    ListaVenta(lineas: _lineas, alSumar: _sumarProducto, alRestar: _restarProducto),
                  if (_esGasto)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final c in _categorias)
                          ChipCaporal(c, seleccionado: c == _categoria, alTocar: () => setState(() => _categoria = c)),
                      ]),
                    ),
                  if (_esPedido) ...[
                    const SizedBox(height: 8),
                    PanelPedido(
                      lineas: _llegada.values.toList(),
                      proveedor: _proveedor,
                      fiado: _meFiaron,
                      alCambiarProveedor: () => setState(() {}),
                      alCambiar: (l) => setState(() => _llegada[l.producto.id] = l),
                      alQuitar: (p) => setState(() => _llegada.remove(p.id)),
                    ),
                  ],
                  if (_esPagoProveedor)
                    CampoProveedor(
                        controlador: _proveedor, etiqueta: '¿A quién le pagó?', alCambiar: () => setState(() {})),
                  if (_esFiado || widget.tipo == TipoMovimiento.abono)
                    TextField(
                      controller: _cliente,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: _esFiado ? '¿A quién le fió?' : '¿Quién le pagó?'),
                    ),
                  if (_esFiado && _cliente.text.trim().isNotEmpty)
                    _CelularAlFiar(
                      nombre: _cliente.text.trim(),
                      controlador: _celularCliente,
                      autoriza: _clienteAutoriza,
                      error: _errorCelular,
                      alCambiar: () => setState(() => _errorCelular = null),
                      alAutorizar: (v) => setState(() {
                        _clienteAutoriza = v;
                        _errorCelular = null;
                      }),
                    ),
                ]),
              ),
            ),
            // El valor y la forma de pago quedan siempre a la vista, junto al teclado.
            const SizedBox(height: 10),
            Tarjeta(
              relleno: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              hijo: Column(children: [
                Text(pesos(_valor), style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _colorMonto)),
              ]),
            ),
            const SizedBox(height: 8),
            if (_esVenta || _esGasto || _esPagoProveedor)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(spacing: 8, children: [
                  ChipCaporal('Efectivo',
                      seleccionado: !_esFiado && _medio == 'EFECTIVO',
                      alTocar: () => setState(() {
                            _medio = 'EFECTIVO';
                            _fiado = false;
                            _meFiaron = false;
                          })),
                  ChipCaporal('Bre-B',
                      seleccionado: !_esFiado && _medio == 'BREB',
                      alTocar: () => setState(() {
                            _medio = 'BREB';
                            _fiado = false;
                            _meFiaron = false;
                          })),
                  if (_esVenta)
                    ChipCaporal('Fiado', seleccionado: _esFiado, alTocar: () => setState(() => _fiado = true)),
                  // El proveedor dejó el pedido y se le paga después: queda en "Le debo", no sale plata hoy.
                  if (_esPedido)
                    ChipCaporal('Me lo fiaron',
                        seleccionado: _meFiaron, alTocar: () => setState(() => _meFiaron = true)),
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
                              child: comoBoton(
                                etiqueta: t == 'Borrar' ? 'Borrar el último número' : (t == '000' ? 'Tres ceros' : t),
                                hijo: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _tecla(t),
                                  child: Center(
                                    child: Text(t,
                                        style: TextStyle(
                                            fontSize: t == 'Borrar' ? 16 : 26,
                                            fontWeight: FontWeight.w600,
                                            color: t == 'Borrar' ? Colores.rojo : Colores.texto)),
                                  ),
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
                _esCompraFiada
                    ? 'Anotar lo que debo'
                    : (_esGasto
                        ? 'Guardar gasto'
                        : (_esFiado ? 'Anotar deuda' : (_esPagoProveedor ? 'Guardar pago' : 'Guardar'))),
                icono: Icons.check,
                alTocar: puedeGuardar ? _guardar : null),
          ]),
        ),
      ),
    );
  }
}

/// Celular del cliente al fiar, para poder recordarle después por WhatsApp. Si ya está guardado,
/// lo muestra; si no, lo pide con la autorización del cliente (sin ella no se guarda).
class _CelularAlFiar extends StatelessWidget {
  final String nombre;
  final TextEditingController controlador;
  final bool autoriza;
  final String? error;
  final VoidCallback alCambiar;
  final ValueChanged<bool> alAutorizar;
  const _CelularAlFiar({
    required this.nombre,
    required this.controlador,
    required this.autoriza,
    required this.error,
    required this.alCambiar,
    required this.alAutorizar,
  });

  @override
  Widget build(BuildContext context) {
    final clientes = context.watch<Clientes>();
    return FutureBuilder<DatosCliente>(
      future: clientes.datos(nombre),
      builder: (_, s) {
        final guardado = s.data?.celular;
        if (guardado != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              const Icon(Icons.phone_outlined, size: 18, color: Colores.gris),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Celular guardado: $guardado', style: const TextStyle(fontSize: 14, color: Colores.gris)),
              ),
            ]),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: controlador,
            keyboardType: TextInputType.phone,
            onChanged: (_) => alCambiar(),
            decoration: InputDecoration(
              labelText: 'Celular de $nombre (opcional)',
              helperText: 'Para recordarle el pago por WhatsApp. Queda solo en este celular.',
              errorText: error,
            ),
          ),
          if (controlador.text.trim().isNotEmpty)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: autoriza,
              onChanged: (v) => alAutorizar(v ?? false),
              title: Text('$nombre aceptó que guarde su número para recordarle pagos',
                  style: const TextStyle(fontSize: 13)),
            ),
        ]);
      },
    );
  }
}
