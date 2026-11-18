import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../dominio/tipos_de_negocio.dart';
import '../../sincronizacion/sesion.dart';

/// El tipo de negocio del dueño, para adaptar categorías, gastos y ejemplos.
/// Si no hay sesión a la mano (por ejemplo, en una prueba de una sola pantalla), el de tienda.
TipoDeNegocio negocioActual(BuildContext context) {
  try {
    return TiposDeNegocio.de(context.read<Sesion>().tipoNegocio);
  } on ProviderNotFoundException {
    return TiposDeNegocio.tienda;
  }
}
