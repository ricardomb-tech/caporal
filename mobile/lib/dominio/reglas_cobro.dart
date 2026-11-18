import 'formato.dart';
import 'movimiento.dart';

/// Reglas para cobrar con respeto: solo en horario razonable y sin insistir.
/// Son prudentes a propósito (inspiradas en las buenas prácticas de cobranza); el dueño
/// siempre decide y envía el mensaje desde su propio WhatsApp.
class ReglasCobro {
  /// Días que se recomienda esperar entre un recordatorio y el siguiente.
  static const diasEntreRecordatorios = 7;

  /// Null si se puede enviar ahora; si no, el motivo para mostrarle al dueño.
  static String? fueraDeHorario(DateTime ahora) {
    final h = ahora.hour;
    switch (ahora.weekday) {
      case DateTime.sunday:
        return 'Hoy es domingo. Para no incomodar, envíelo mañana entre 7 a. m. y 7 p. m.';
      case DateTime.saturday:
        if (h < 8 || h >= 15) return 'Los sábados es mejor recordar entre 8 a. m. y 3 p. m.';
        return null;
      default:
        if (h < 7 || h >= 19) return 'Es mejor recordar entre 7 a. m. y 7 p. m. Envíelo más tarde o mañana.';
        return null;
    }
  }

  /// Aviso (no bloquea) si se le recordó hace poco.
  static String? recordadoHacePoco(DateTime ahora, DateTime? ultimo) {
    if (ultimo == null) return null;
    final dias = ahora.difference(ultimo).inDays;
    if (dias >= diasEntreRecordatorios) return null;
    final cuando = dias == 0 ? 'hoy' : (dias == 1 ? 'ayer' : 'hace $dias días');
    return 'Ya le recordó $cuando. Para no incomodar, espere unos días antes de volver a escribirle.';
  }
}

/// Lo que el cliente quedó debiendo: los fiados vigentes (sin los corregidos).
class FiadosVigentes {
  final List<Movimiento> fiados;
  const FiadosVigentes(this.fiados);

  factory FiadosVigentes.de(List<Movimiento> movimientos) {
    final corregidos = {for (final m in movimientos) if (m.reversoDe != null) m.reversoDe!};
    final lista = movimientos
        .where((m) => m.tipo == TipoMovimiento.fiado && m.reversoDe == null && !corregidos.contains(m.id))
        .toList()
      ..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    return FiadosVigentes(lista);
  }

  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  /// "2 fiados: 12 y 21 de octubre", "1 fiado: 3 de noviembre", "3 fiados: 30 de octubre, 2 y 5 de noviembre".
  String get detalle {
    if (fiados.isEmpty) return '';
    final porMes = <int, List<int>>{};
    final orden = <int>[];
    for (final m in fiados) {
      final f = m.creadoEn.toLocal();
      final clave = f.year * 12 + f.month - 1;
      if (!porMes.containsKey(clave)) orden.add(clave);
      final dias = porMes.putIfAbsent(clave, () => []);
      if (!dias.contains(f.day)) dias.add(f.day);
    }
    final partes = [for (final c in orden) '${_unir(porMes[c]!.map((d) => '$d').toList())} de ${_meses[c % 12]}'];
    final n = fiados.length;
    return '$n ${n == 1 ? 'fiado' : 'fiados'}: ${_unir(partes)}';
  }

  static String _unir(List<String> xs) =>
      xs.length == 1 ? xs.first : '${xs.sublist(0, xs.length - 1).join(', ')} y ${xs.last}';
}

/// Arma el recordatorio amable. Nunca menciona intereses, recargos ni consecuencias.
String mensajeCobro({
  required String cliente,
  required int saldo,
  String? quienCobra,
  String? negocio,
  String? llaveBreB,
}) {
  final saludo = StringBuffer('Hola, $cliente.');
  if (quienCobra != null && quienCobra.trim().isNotEmpty) {
    saludo.write(' Le saluda ${quienCobra.trim()}');
    saludo.write(negocio != null && negocio.trim().isNotEmpty ? ', de ${negocio.trim()}.' : '.');
  } else if (negocio != null && negocio.trim().isNotEmpty) {
    saludo.write(' Le saludamos de ${negocio.trim()}.');
  }
  saludo.write(' Le recuerdo con mucho gusto que tiene un saldo pendiente de ${pesos(saldo)}.');
  final pago = (llaveBreB != null && llaveBreB.trim().isNotEmpty)
      ? 'Puede pagarme por Bre-B a la llave ${llaveBreB.trim()}. ¡Muchas gracias!'
      : 'Puede pagarme cuando pase por el negocio. ¡Muchas gracias!';
  return '$saludo\n\n$pago';
}
