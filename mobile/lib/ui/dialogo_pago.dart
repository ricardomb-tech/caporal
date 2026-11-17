import 'package:flutter/material.dart';

import '../data/repositorio.dart';
import 'pantalla_registrar_pago.dart';

/// "Ya me pagó": abre el registro guiado del pago. Devuelve true si se anotó un pago.
Future<bool> anotarPago(BuildContext context, Deudor deudor) async {
  final ok = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => PantallaRegistrarPago(deudor: deudor)));
  return ok == true;
}
