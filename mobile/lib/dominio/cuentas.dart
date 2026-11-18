import 'movimiento.dart';
import 'tipos_de_negocio.dart';

/// Las cuentas de un periodo (hoy, la semana o el mes), en palabras de negocio.
///
/// - **Ganó:** lo que vendió, menos lo que le costó esa mercancía, menos los otros gastos (arriendo,
///   servicios…). Un pedido de mercancía NO es pérdida: la mercancía sigue en el estante hasta venderse.
/// - **Le quedó en plata:** lo que entró a la caja (ventas de contado y pagos de fiados) menos lo que
///   salió (gastos, pedidos pagados y pagos a proveedores). Es distinto de la ganancia: fiar, comprar
///   mercancía o cobrar fiados viejos mueve la plata sin cambiar lo que ganó.
class Cuentas {
  final int ventasDeContado;
  final int ventasFiadas;

  /// Lo que le pagaron sus clientes de lo que les fió (de este periodo o de antes).
  final int cobrosDeFiados;

  /// Pedidos de mercancía pagados y pagos a proveedores.
  final int mercanciaPagada;

  /// Pedidos que le fiaron los proveedores en el periodo (todavía no sale plata).
  final int pedidosFiados;

  /// Gastos que no son mercancía, por categoría (Arriendo, Servicios…), de mayor a menor.
  final Map<String, int> otrosGastos;

  /// De lo vendido, lo que tiene costo anotado, y cuánto costó eso.
  final int vendidoConCosto;
  final int costoConocido;

  /// Ganancia que eligió el dueño (%), para estimar el costo de lo que no tiene costo anotado.
  final int margen;

  const Cuentas({
    this.ventasDeContado = 0,
    this.ventasFiadas = 0,
    this.cobrosDeFiados = 0,
    this.mercanciaPagada = 0,
    this.pedidosFiados = 0,
    this.otrosGastos = const {},
    this.vendidoConCosto = 0,
    this.costoConocido = 0,
    this.margen = 25,
  });

  /// Suma los movimientos del periodo (un reverso resta lo que anuló).
  factory Cuentas.de(List<Movimiento> movimientos,
      {int vendidoConCosto = 0, int costoConocido = 0, required int margen}) {
    var contado = 0, fiado = 0, cobros = 0, mercancia = 0, pedidosFiados = 0;
    final otros = <String, int>{};
    for (final m in movimientos) {
      final v = m.reversoDe == null ? m.valor : -m.valor;
      switch (m.tipo) {
        case TipoMovimiento.venta:
          contado += v;
        case TipoMovimiento.fiado:
          fiado += v;
        case TipoMovimiento.abono:
          cobros += v;
        case TipoMovimiento.pago:
          mercancia += v;
        case TipoMovimiento.compra:
          pedidosFiados += v;
        case TipoMovimiento.gasto:
          final categoria = categoriaDeGasto(m.descripcion);
          if (categoria == TiposDeNegocio.pedido) {
            mercancia += v;
          } else {
            otros[categoria] = (otros[categoria] ?? 0) + v;
          }
      }
    }
    otros.removeWhere((_, v) => v == 0);
    final ordenados = Map.fromEntries(otros.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    return Cuentas(
      ventasDeContado: contado,
      ventasFiadas: fiado,
      cobrosDeFiados: cobros,
      mercanciaPagada: mercancia,
      pedidosFiados: pedidosFiados,
      otrosGastos: ordenados,
      vendidoConCosto: vendidoConCosto,
      costoConocido: costoConocido,
      margen: margen,
    );
  }

  /// La categoría con que se anotó un gasto ("Arriendo · local" → Arriendo); si no se reconoce, Otro.
  static String categoriaDeGasto(String? descripcion) {
    final primera = (descripcion ?? '').split(' · ').first.trim();
    return TiposDeNegocio.todasLasDeGasto.contains(primera) ? primera : TiposDeNegocio.otro;
  }

  int get vendio => ventasDeContado + ventasFiadas;
  int get totalOtrosGastos => otrosGastos.values.fold(0, (a, v) => a + v);

  // ---- La ganancia ----

  /// Lo vendido que no tiene costo anotado (productos sin costo o ventas escritas en el teclado).
  int get vendidoSinCosto => vendio - vendidoConCosto > 0 ? vendio - vendidoConCosto : 0;

  /// Costo de lo que no tiene costo anotado, calculado con la ganancia que eligió:
  /// si gana 25 %, lo que vendió en $ 2.500 le costó $ 2.000.
  int get costoEstimado => (vendidoSinCosto * 100 / (100 + margen)).round();

  int get costoDeLoVendido => costoConocido + costoEstimado;

  /// Si parte del costo se calculó con el porcentaje (no con lo que de verdad pagó).
  bool get gananciaAproximada => vendidoSinCosto > 0;

  int get ganancia => vendio - costoDeLoVendido - totalOtrosGastos;

  // ---- La plata ----

  int get entro => ventasDeContado + cobrosDeFiados;
  int get salio => mercanciaPagada + totalOtrosGastos;
  int get quedoEnPlata => entro - salio;

  /// En qué se fue la plata, de mayor a menor: la mercancía y luego cada gasto.
  List<(String, int)> get enQueGasto {
    final lista = [
      if (mercanciaPagada != 0) ('Mercancía', mercanciaPagada),
      for (final e in otrosGastos.entries) (e.key, e.value),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return lista;
  }
}

/// Lo que vale el negocio hoy (su capital de trabajo), sin contar la plata que tenga en la caja.
class Capital {
  /// Mercancía guardada, a lo que le costó (estimado con la ganancia si falta el costo de algún producto).
  final int mercancia;
  final bool mercanciaAproximada;
  final int leDeben;
  final int debe;
  const Capital({required this.mercancia, this.mercanciaAproximada = false, required this.leDeben, required this.debe});

  int get total => mercancia + leDeben - debe;
}
