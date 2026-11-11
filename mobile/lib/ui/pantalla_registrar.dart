import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/movimiento.dart';
import '../data/repositorio.dart';
import '../formato.dart';
import 'pantalla_exito.dart';
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
  static const _categorias = ['Mercado', 'Arriendo', 'Servicios', 'Transporte', 'Otro'];

  String _digitos = '';
  late final TextEditingController _cliente = TextEditingController(text: widget.clienteInicial ?? '');
  final _nota = TextEditingController();
  final List<String> _items = [];
  String _categoria = _categorias.first;
  String _medio = 'EFECTIVO';
  bool _guardando = false;

  int get _valor => _digitos.isEmpty ? 0 : int.parse(_digitos);
  bool get _esFiado => widget.tipo == TipoMovimiento.fiado;
  bool get _esGasto => widget.tipo == TipoMovimiento.gasto;
  bool get _esVenta => widget.tipo == TipoMovimiento.venta;

  String get _titulo => switch (widget.tipo) {
        TipoMovimiento.venta => 'Vendí',
        TipoMovimiento.gasto => 'Gasté',
        TipoMovimiento.fiado => 'Fié',
        TipoMovimiento.abono => 'Me pagaron',
      };

  String get _subtitulo => switch (widget.tipo) {
        TipoMovimiento.venta => 'Toque un producto o escriba el valor',
        TipoMovimiento.gasto => 'Anote lo que pagó hoy',
        TipoMovimiento.fiado => 'Anote lo que le quedan debiendo',
        TipoMovimiento.abono => 'Anote lo que le pagaron',
      };

  Color get _colorMonto => _esGasto ? Colores.rojo : (_esFiado ? Colores.ambarTexto : Colores.verde);

  void _tecla(String t) {
    setState(() {
      if (t == 'Borrar') {
        if (_digitos.isNotEmpty) _digitos = _digitos.substring(0, _digitos.length - 1);
        if (_digitos.isEmpty) _items.clear();
      } else if (_digitos.length + t.length <= 9) {
        _digitos = (_digitos + t).replaceFirst(RegExp(r'^0+'), '');
      }
    });
  }

  void _sumarProducto(Producto p) {
    setState(() {
      _digitos = (_valor + p.precio).toString();
      _items.add(p.nombre);
    });
  }

  String? get _descripcion {
    if (_esGasto) {
      final n = _nota.text.trim();
      return n.isEmpty ? _categoria : '$_categoria · $n';
    }
    if (_items.isEmpty) return null;
    final cuenta = <String, int>{};
    for (final i in _items) {
      cuenta[i] = (cuenta[i] ?? 0) + 1;
    }
    return cuenta.entries.map((e) => e.value > 1 ? '${e.value} ${e.key}' : e.key).join(', ');
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final m = await context.read<Repositorio>().registrar(
          tipo: widget.tipo,
          valor: _valor,
          descripcion: _descripcion,
          clienteNombre: (_esFiado || widget.tipo == TipoMovimiento.abono) ? _cliente.text.trim() : null,
          medioPago: (_esVenta || _esGasto) ? _medio : null,
        );
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PantallaExito(movimiento: m)));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<Repositorio>();
    final puedeGuardar = _valor > 0 && !_guardando && (!_esFiado || _cliente.text.trim().isNotEmpty);
    return Scaffold(
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
            const SizedBox(height: 12),
            if (_esVenta)
              SizedBox(
                height: 62,
                child: FutureBuilder<List<Producto>>(
                  future: repo.productos(),
                  builder: (_, s) {
                    final lista = s.data ?? const <Producto>[];
                    if (lista.isEmpty) {
                      return const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Agregue sus productos en Ajustes para anotar con un toque.',
                              style: TextStyle(fontSize: 13, color: Colores.gris)));
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _sumarProducto(lista[i]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(lista[i].nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(pesos(lista[i].precio), style: const TextStyle(fontSize: 12, color: Colores.gris)),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_esGasto)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in _categorias) ChipCaporal(c, seleccionado: c == _categoria, alTocar: () => setState(() => _categoria = c)),
                ]),
              ),
            if (_esFiado || widget.tipo == TipoMovimiento.abono)
              TextField(
                controller: _cliente,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: _esFiado ? '¿A quién le fió?' : '¿Quién le pagó?'),
              ),
            const SizedBox(height: 10),
            Tarjeta(
              relleno: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              hijo: Column(children: [
                if (_descripcion != null && !_esGasto)
                  Text(_descripcion!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colores.gris)),
                Text(pesos(_valor), style: TextStyle(fontSize: 46, fontWeight: FontWeight.bold, color: _colorMonto)),
              ]),
            ),
            const SizedBox(height: 10),
            if (_esVenta || _esGasto)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(spacing: 8, children: [
                  ChipCaporal('Efectivo', seleccionado: _medio == 'EFECTIVO', alTocar: () => setState(() => _medio = 'EFECTIVO')),
                  ChipCaporal('Bre-B', seleccionado: _medio == 'BREB', alTocar: () => setState(() => _medio = 'BREB')),
                ]),
              ),
            Expanded(
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
                                          color: t == 'Borrar' ? Colores.rojo : Colores.texto)),
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
            BotonCaporal(_esGasto ? 'Guardar gasto' : (_esFiado ? 'Anotar deuda' : 'Guardar'),
                icono: Icons.check, alTocar: puedeGuardar ? _guardar : null),
          ]),
        ),
      ),
    );
  }
}
