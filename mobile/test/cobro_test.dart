import 'package:caporal/dominio/reglas_cobro.dart';
import 'package:caporal/dominio/movimiento.dart';
import 'package:flutter_test/flutter_test.dart';

Movimiento _mov(String id, TipoMovimiento tipo, DateTime cuando, {String? reversoDe}) => Movimiento(
    id: id, tipo: tipo, valor: 10000, dispositivoId: 't', creadoEn: cuando, clienteNombre: 'José', reversoDe: reversoDe);

void main() {
  group('horario para cobrar', () {
    test('entre semana de 7 a. m. a 7 p. m. se puede', () {
      expect(ReglasCobro.fueraDeHorario(DateTime(2026, 11, 17, 7)), isNull); // martes
      expect(ReglasCobro.fueraDeHorario(DateTime(2026, 11, 17, 18, 59)), isNull);
    });
    test('entre semana fuera de horario no', () {
      expect(ReglasCobro.fueraDeHorario(DateTime(2026, 11, 17, 6, 59)), isNotNull);
      expect(ReglasCobro.fueraDeHorario(DateTime(2026, 11, 17, 19)), isNotNull);
    });
    test('sábado solo de 8 a. m. a 3 p. m.', () {
      expect(ReglasCobro.fueraDeHorario(DateTime(2026, 11, 21, 8)), isNull);
      expect(ReglasCobro.fueraDeHorario(DateTime(2026, 11, 21, 15)), isNotNull);
    });
    test('domingo nunca', () {
      expect(ReglasCobro.fueraDeHorario(DateTime(2026, 11, 22, 10)), isNotNull);
    });
  });

  group('frecuencia', () {
    final ahora = DateTime(2026, 11, 17, 10);
    test('sin recordatorio previo no avisa', () => expect(ReglasCobro.recordadoHacePoco(ahora, null), isNull));
    test('hace 3 días avisa', () {
      expect(ReglasCobro.recordadoHacePoco(ahora, ahora.subtract(const Duration(days: 3))), contains('hace 3 días'));
    });
    test('hace una semana ya no avisa', () {
      expect(ReglasCobro.recordadoHacePoco(ahora, ahora.subtract(const Duration(days: 7))), isNull);
    });
  });

  group('fiados vigentes', () {
    test('agrupa días por mes como en el diseño', () {
      final f = FiadosVigentes.de([
        _mov('a', TipoMovimiento.fiado, DateTime(2026, 10, 12, 10)),
        _mov('b', TipoMovimiento.fiado, DateTime(2026, 10, 21, 10)),
        _mov('c', TipoMovimiento.abono, DateTime(2026, 10, 25, 10)),
      ]);
      expect(f.detalle, '2 fiados: 12 y 21 de octubre');
    });
    test('no cuenta un fiado corregido', () {
      final f = FiadosVigentes.de([
        _mov('a', TipoMovimiento.fiado, DateTime(2026, 10, 30, 10)),
        _mov('b', TipoMovimiento.fiado, DateTime(2026, 11, 2, 10)),
        _mov('r', TipoMovimiento.fiado, DateTime(2026, 11, 3, 10), reversoDe: 'b'),
        _mov('c', TipoMovimiento.fiado, DateTime(2026, 11, 5, 10)),
      ]);
      expect(f.detalle, '2 fiados: 30 de octubre y 5 de noviembre');
    });
  });

  group('mensaje', () {
    test('con quien cobra, negocio y llave Bre-B', () {
      final m = mensajeCobro(
          cliente: 'don José', saldo: 85000, quienCobra: 'Marta', negocio: 'la Tienda La Esperanza', llaveBreB: '3101234567');
      expect(m, startsWith('Hola, don José. Le saluda Marta, de la Tienda La Esperanza.'));
      expect(m, contains('saldo pendiente de \$ 85.000'));
      expect(m, contains('Bre-B a la llave 3101234567'));
    });
    test('sin llave invita a pagar en el negocio', () {
      expect(mensajeCobro(cliente: 'Ana', saldo: 5000), contains('cuando pase por el negocio'));
    });
    test('nunca habla de intereses, recargos ni reportes', () {
      final m = mensajeCobro(cliente: 'Ana', saldo: 5000, negocio: 'Tienda', llaveBreB: 'x').toLowerCase();
      for (final palabra in ['interés', 'interes', 'mora', 'recargo', 'reporte', 'datacrédito', 'abogado']) {
        expect(m, isNot(contains(palabra)));
      }
    });
  });
}
