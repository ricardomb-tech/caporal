import 'formato.dart';

/// Costo, precio y ganancia, en palabras de tienda. La ganancia se cuenta sobre lo que costó:
/// "si me cuesta $ 2.000 y le gano 25 %, lo vendo a $ 2.500".
class Precios {
  Precios._();

  /// Lo que el tendero elige ganar en cada producto (Mi negocio).
  static const margenes = [15, 20, 25, 30];
  static const margenRecomendado = 25;

  /// Precio de venta para ganar [margen] % sobre [costo], redondeado hacia arriba a un valor de tienda
  /// ($ 50 si es menos de $ 1.000; $ 100 hasta $ 10.000; $ 500 hasta $ 100.000; $ 1.000 desde ahí).
  /// Hacia arriba, para no ganar nunca menos de lo que se eligió.
  static int sugerido(int costo, int margen) {
    if (costo <= 0) return 0;
    final crudo = costo * (100 + margen) / 100;
    final p = _paso(crudo);
    return (crudo / p).ceil() * p;
  }

  static int _paso(num valor) => valor < 1000
      ? 50
      : valor < 10000
          ? 100
          : valor < 100000
              ? 500
              : 1000;

  static int ganancia(int precio, int costo) => precio - costo;

  /// Ganancia sobre el costo, en %. 0 si no hay costo.
  static int porcentaje(int precio, int costo) => costo <= 0 ? 0 : ((precio - costo) * 100 / costo).round();

  /// "Gana $ 500 por cada una (25 %)" o, si pierde, "Pierde $ 200 por cada una".
  static String explicar(int precio, int costo) {
    final g = ganancia(precio, costo);
    if (g < 0) return 'Pierde ${pesos(-g)} por cada una';
    return 'Gana ${pesos(g)} por cada una (${porcentaje(precio, costo)} %)';
  }

  /// Si con ese precio gana menos de lo que eligió.
  static bool ganaMenos(int precio, int costo, int margen) => costo > 0 && porcentaje(precio, costo) < margen;
}
