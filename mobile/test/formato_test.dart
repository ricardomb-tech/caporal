import 'package:caporal/data/movimiento.dart';
import 'package:caporal/formato.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pesos separa miles con punto', () {
    expect(pesos(0), r'$ 0');
    expect(pesos(500), r'$ 500');
    expect(pesos(45000), r'$ 45.000');
    expect(pesos(1250000), r'$ 1.250.000');
    expect(pesos(-59000), r'- $ 59.000');
  });

  test('el movimiento conserva sus datos al guardarse y leerse', () {
    final m = Movimiento(
      id: 'a1',
      tipo: TipoMovimiento.fiado,
      valor: 20000,
      clienteNombre: 'Don José',
      dispositivoId: 'tel-1',
      creadoEn: DateTime.utc(2026, 11, 11, 16, 15),
    );
    final copia = Movimiento.deFila(m.aFila());
    expect(copia.id, m.id);
    expect(copia.tipo, TipoMovimiento.fiado);
    expect(copia.valor, 20000);
    expect(copia.clienteNombre, 'Don José');
    expect(copia.creadoEn, m.creadoEn);
    expect(m.aJson()['tipo'], 'FIADO');
    expect(m.aJson()['creadoEnDispositivo'], '2026-11-11T16:15:00.000Z');
  });
}
