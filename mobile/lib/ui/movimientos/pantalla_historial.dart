import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dominio/movimiento.dart';
import '../../datos/repositorio.dart';
import '../../dominio/formato.dart';
import 'pantalla_detalle.dart';
import '../comun/tema.dart';
import '../comun/widgets.dart';

String _hora(DateTime f) {
  final h = f.hour % 12 == 0 ? 12 : f.hour % 12;
  return '$h:${f.minute.toString().padLeft(2, '0')} ${f.hour < 12 ? 'a. m.' : 'p. m.'}';
}

/// Signo con que se muestra un movimiento; un reverso invierte el del original.
String signoDe(Movimiento m) {
  final ingreso = m.tipo == TipoMovimiento.venta || m.tipo == TipoMovimiento.abono;
  // Lo fiado (al cliente o por el proveedor) no mueve plata todavía: va sin signo.
  final sinPlata = m.tipo == TipoMovimiento.fiado || m.tipo == TipoMovimiento.compra;
  final base = ingreso ? 1 : -1;
  final s = m.reversoDe == null ? base : -base;
  if (sinPlata) return m.reversoDe == null ? '' : '− ';
  return s > 0 ? '+ ' : '− ';
}

String nombreTipo(Movimiento m) {
  final base = switch (m.tipo) {
    TipoMovimiento.venta => 'Venta',
    TipoMovimiento.gasto => 'Gasto',
    TipoMovimiento.fiado => 'Fiado',
    TipoMovimiento.abono => 'Abono',
    TipoMovimiento.compra => 'Pedido fiado',
    TipoMovimiento.pago => 'Pago a proveedor',
  };
  return m.reversoDe == null ? base : 'Reverso de $base';
}

/// Fila de un movimiento, usada en el inicio y en el historial.
class FilaMovimiento extends StatelessWidget {
  final Movimiento m;

  /// null = no mostrar el estado de envío.
  final bool? pendiente;
  const FilaMovimiento({super.key, required this.m, this.pendiente});

  @override
  Widget build(BuildContext context) {
    final (letra, color, fondo) = switch (m.tipo) {
      TipoMovimiento.venta => ('V', Colores.verde, Colores.verdeClaro),
      TipoMovimiento.gasto => ('G', Colores.rojo, Colores.rojoClaro),
      TipoMovimiento.fiado => ('F', Colores.ambarTexto, Colores.ambarClaro),
      TipoMovimiento.abono => ('A', Colores.verde, Colores.verdeClaro),
      TipoMovimiento.compra => ('P', Colores.ambarTexto, Colores.ambarClaro),
      TipoMovimiento.pago => ('P', Colores.rojo, Colores.rojoClaro),
    };
    final detalle = m.clienteNombre ?? m.descripcion;
    return FilaLista(
      inicio: Insignia.letra(letra, color, fondo),
      titulo: detalle == null ? nombreTipo(m) : '${nombreTipo(m)} · $detalle',
      detalle: _hora(m.creadoEn.toLocal()),
      alTocar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalle(movimiento: m))),
      fin: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${signoDe(m)}${pesos(m.valor)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        if (pendiente != null)
          Text(pendiente! ? 'Pendiente' : 'Enviado',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: pendiente! ? Colores.ambarTexto : Colores.gris)),
      ]),
    );
  }
}

class PantallaHistorial extends StatefulWidget {
  const PantallaHistorial({super.key});

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  int _filtro = 0; // 0 hoy, 1 semana, 2 mes

  DateTime get _inicio {
    final n = DateTime.now();
    final hoy = DateTime(n.year, n.month, n.day);
    return switch (_filtro) { 0 => hoy, 1 => hoy.subtract(const Duration(days: 6)), _ => DateTime(n.year, n.month, 1) };
  }

  String _etiquetaDia(DateTime f) {
    final n = DateTime.now();
    final hoy = DateTime(n.year, n.month, n.day);
    final dia = DateTime(f.year, f.month, f.day);
    final dif = hoy.difference(dia).inDays;
    if (dif == 0) return 'Hoy';
    if (dif == 1) return 'Ayer';
    return '${dia.day}/${dia.month}/${dia.year}';
  }

  Future<(List<Movimiento>, Set<String>)> _cargar(Repositorio repo) async {
    final lista = await repo.desde(_inicio);
    final pendientes = await repo.idsPendientes();
    return (lista, pendientes);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repositorio>();
    return Pantalla(
      titulo: 'Movimientos',
      subtitulo: 'Lo último que anotó',
      hijos: [
        Row(children: [
          for (final (i, t) in ['Hoy', 'Semana', 'Mes'].indexed) ...[
            ChipCaporal(t, seleccionado: _filtro == i, alTocar: () => setState(() => _filtro = i)),
            const SizedBox(width: 8),
          ],
        ]),
        FutureBuilder<(List<Movimiento>, Set<String>)>(
          future: _cargar(repo),
          builder: (_, s) {
            final datos = s.data;
            if (datos == null) return const SizedBox.shrink();
            final (lista, pendientes) = datos;
            if (lista.isEmpty) {
              return const Tarjeta(
                  hijo:
                      Text('No hay movimientos en este período.', style: TextStyle(fontSize: 15, color: Colores.gris)));
            }
            final filas = <Widget>[];
            String? ultimo;
            for (final m in lista) {
              final etiqueta = _etiquetaDia(m.creadoEn.toLocal());
              if (etiqueta != ultimo) {
                if (ultimo != null) filas.add(lineaSuave);
                filas.add(Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(etiqueta,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.gris))));
                ultimo = etiqueta;
              }
              filas.add(FilaMovimiento(m: m, pendiente: pendientes.contains(m.id)));
            }
            return Tarjeta(
                relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), hijo: Column(children: filas));
          },
        ),
        const Text('Un movimiento nunca se borra: si hubo un error, se corrige. Toque uno para verlo.',
            style: TextStyle(fontSize: 13, color: Colores.gris)),
      ],
    );
  }
}
