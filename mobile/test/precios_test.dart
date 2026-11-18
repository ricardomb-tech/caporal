import 'package:caporal/dominio/precios.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sugiere el precio con la ganancia elegida y lo redondea a un valor de tienda', () {
    expect(Precios.sugerido(2000, 25), 2500);
    expect(Precios.sugerido(1950, 25), 2500); // 2437,5 → 2.500
    expect(Precios.sugerido(300, 30), 400); // 390 → 400
    expect(Precios.sugerido(12000, 20), 14500); // 14.400 → 14.500
    expect(Precios.sugerido(180000, 15), 207000);
    expect(Precios.sugerido(0, 25), 0);
  });

  test('nunca sugiere ganar menos de lo elegido', () {
    for (final costo in [137, 999, 1001, 4321, 77777]) {
      for (final m in Precios.margenes) {
        expect(Precios.porcentaje(Precios.sugerido(costo, m), costo), greaterThanOrEqualTo(m));
      }
    }
  });

  test('explica la ganancia en pesos y en %', () {
    expect(Precios.explicar(2500, 2000), 'Gana \$ 500 por cada una (25 %)');
    expect(Precios.explicar(1800, 2000), 'Pierde \$ 200 por cada una');
    expect(Precios.ganaMenos(2500, 2200, 25), isTrue);
    expect(Precios.ganaMenos(2750, 2200, 25), isFalse);
  });
}
