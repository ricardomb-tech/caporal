import 'formato.dart';

/// Lo que la app le puede avisar al dueño. Cada uno se puede apagar en Ajustes → Avisos.
enum TipoAviso {
  cobros('Cobros pendientes', 'Clientes que le deben hace más de 15 días'),
  agotados('Productos por acabarse', 'Cuando quedan 3 o menos de un producto'),
  proveedores('Pagos a proveedores', 'Pedidos fiados de hace más de 8 días'),
  cierre('Cierre del día', 'A las 7:30 p. m., para anotar lo que falte y ver cuánto ganó'),
  copia('Copia de seguridad', 'Si hay anotaciones sin copia desde hace más de 2 días');

  final String nombre;
  final String explicacion;
  const TipoAviso(this.nombre, this.explicacion);

  /// Id fijo de la notificación: programar de nuevo reemplaza la anterior del mismo tipo.
  int get id => index + 1;
}

class Aviso {
  final TipoAviso tipo;
  final DateTime cuando;
  final String titulo;
  final String cuerpo;
  const Aviso(this.tipo, this.cuando, this.titulo, this.cuerpo);

  @override
  String toString() => '$tipo @ $cuando: $titulo · $cuerpo';
}

/// Lo que se sabe del negocio al momento de programar los avisos.
class EstadoParaAvisos {
  /// Clientes que deben: nombre, saldo y desde cuándo.
  final List<(String, int, DateTime)> deudores;

  /// Proveedores a los que se les debe: nombre, saldo y desde cuándo.
  final List<(String, int, DateTime)> proveedores;

  /// Productos que llevan cantidad: nombre y cuántos quedan.
  final List<(String, int)> productos;

  /// Anotaciones sin copia de seguridad y desde cuándo está la más vieja (null si no hay).
  final int sinCopia;
  final DateTime? sinCopiaDesde;

  const EstadoParaAvisos({
    this.deudores = const [],
    this.proveedores = const [],
    this.productos = const [],
    this.sinCopia = 0,
    this.sinCopiaDesde,
  });
}

/// Decide qué avisar y a qué hora, sin tocar el sistema (se puede probar sin celular).
///
/// Respeta el descanso: los avisos salen entre las 8 a. m. y las 7:30 p. m. Con [conDetalle] en false
/// (lo predeterminado) no muestra nombres ni valores, porque el aviso se ve en la pantalla bloqueada.
class PlanAvisos {
  PlanAvisos._();

  static const diasCobro = 15;
  static const diasProveedor = 8;
  static const pocasUnidades = 3;
  static const diasSinCopia = 2;

  static List<Aviso> planear(
    EstadoParaAvisos e, {
    required DateTime ahora,
    required Set<TipoAviso> activos,
    bool conDetalle = false,
  }) {
    DateTime proxima(int hora, int minuto) {
      final hoy = DateTime(ahora.year, ahora.month, ahora.day, hora, minuto);
      return hoy.isAfter(ahora) ? hoy : hoy.add(const Duration(days: 1));
    }

    int dias(DateTime desde) => ahora.difference(desde).inDays;
    String lista(List<String> nombres) =>
        nombres.length <= 2 ? nombres.join(' y ') : '${nombres.take(2).join(', ')} y ${nombres.length - 2} más';

    final avisos = <Aviso>[];

    if (activos.contains(TipoAviso.cobros)) {
      final viejos = [
        for (final d in e.deudores)
          if (dias(d.$3) > diasCobro) d
      ]..sort((a, b) => a.$3.compareTo(b.$3));
      if (viejos.isNotEmpty) {
        final d = viejos.first;
        final cuerpo = !conDetalle
            ? (viejos.length == 1
                ? 'Un cliente le debe desde hace más de $diasCobro días. Toque para cobrarle por WhatsApp.'
                : '${viejos.length} clientes le deben desde hace más de $diasCobro días. Toque para cobrarles.')
            : (viejos.length == 1
                ? '${d.$1} le debe ${pesos(d.$2)} hace ${dias(d.$3)} días. Toque para cobrarle.'
                : '${lista([for (final v in viejos) v.$1])} le deben hace más de $diasCobro días.');
        avisos.add(Aviso(TipoAviso.cobros, proxima(9, 0), 'Cobros pendientes', cuerpo));
      }
    }

    if (activos.contains(TipoAviso.agotados)) {
      final pocos = [
        for (final p in e.productos)
          if (p.$2 <= pocasUnidades) p
      ]..sort((a, b) => a.$2.compareTo(b.$2));
      if (pocos.isNotEmpty) {
        final cuerpo = conDetalle
            ? 'Se está acabando: ${lista([for (final p in pocos) '${p.$1} (${p.$2})'])}.'
            : (pocos.length == 1
                ? 'Un producto se está acabando. Revise su inventario.'
                : '${pocos.length} productos se están acabando. Revise su inventario.');
        avisos.add(Aviso(TipoAviso.agotados, proxima(8, 0), 'Productos por acabarse', cuerpo));
      }
    }

    if (activos.contains(TipoAviso.proveedores)) {
      final viejos = [
        for (final p in e.proveedores)
          if (dias(p.$3) > diasProveedor) p
      ];
      if (viejos.isNotEmpty) {
        final total = viejos.fold<int>(0, (a, p) => a + p.$2);
        final cuerpo = conDetalle
            ? 'Le debe ${pesos(total)} a ${lista([for (final p in viejos) p.$1])}.'
            : 'Tiene pedidos fiados de hace más de $diasProveedor días. Revise "Le debo".';
        avisos.add(Aviso(TipoAviso.proveedores, proxima(9, 30), 'Pagos a proveedores', cuerpo));
      }
    }

    if (activos.contains(TipoAviso.copia) &&
        e.sinCopia > 0 &&
        e.sinCopiaDesde != null &&
        dias(e.sinCopiaDesde!) >= diasSinCopia) {
      avisos.add(Aviso(TipoAviso.copia, proxima(10, 0), 'Copia de seguridad pendiente',
          'Hay ${e.sinCopia} ${e.sinCopia == 1 ? 'anotación' : 'anotaciones'} sin copia. Abra Caporal con Internet para guardarlas.'));
    }

    if (activos.contains(TipoAviso.cierre)) {
      avisos.add(Aviso(TipoAviso.cierre, proxima(19, 30), 'Cierre del día',
          '¿Ya anotó todo lo de hoy? Toque para ver cuánto ganó.'));
    }

    return avisos;
  }
}
