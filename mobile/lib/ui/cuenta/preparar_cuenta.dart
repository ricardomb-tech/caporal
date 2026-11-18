import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../datos/comprobantes.dart';
import '../../datos/repositorio.dart';
import '../../sincronizacion/cambio_de_cuenta.dart';
import '../../sincronizacion/sesion.dart';
import '../comun/tema.dart';

/// Antes de crear una cuenta o entrar con otro número: si en el celular hay datos de otra cuenta,
/// avisa y los quita para que no se mezclen. Devuelve false si la persona prefirió no seguir.
Future<bool> prepararCuenta(BuildContext context, String celular, {required bool esRegistro}) async {
  final cambio = CambioDeCuenta(context.read<Repositorio>(), context.read<Comprobantes>(), context.read<Sesion>());
  if (!await cambio.hayQueLimpiar(celular, esRegistro: esRegistro)) return true;
  final sinEnviar = await cambio.sinEnviar();
  if (!context.mounted) return false;
  final seguir = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('Este celular tiene datos de otra cuenta'),
      content: Text(sinEnviar > 0
          ? 'Hay $sinEnviar ${sinEnviar == 1 ? 'anotación' : 'anotaciones'} de la otra cuenta que todavía no se '
              'han enviado. Si continúa, se borran de este celular y no se podrán recuperar.'
          : 'Lo de la otra cuenta ya está guardado en el servidor. Se quitará de este celular para que no se '
              'mezcle con la cuenta nueva; su dueño lo recupera al entrar con su número.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
        FilledButton(
          style: sinEnviar > 0 ? FilledButton.styleFrom(backgroundColor: Colores.rojo) : null,
          onPressed: () => Navigator.pop(d, true),
          child: Text(sinEnviar > 0 ? 'Borrar y continuar' : 'Continuar'),
        ),
      ],
    ),
  );
  if (seguir != true) return false;
  await cambio.limpiar();
  return true;
}
