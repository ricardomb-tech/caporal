import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/movimiento.dart';
import '../data/repositorio.dart';
import '../formato.dart';

/// "Ya me pagó": todo o una parte. Devuelve true si se anotó un pago.
Future<bool> anotarPago(BuildContext context, Deudor deudor) async {
  final repo = context.read<Repositorio>();
  final c = TextEditingController();
  final valor = await showDialog<int>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text('¿Cuánto le pagó ${deudor.nombre}?'),
      content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Si pagó una parte, escriba cuánto')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(d, int.tryParse(c.text.trim())), child: const Text('Una parte')),
        FilledButton(onPressed: () => Navigator.pop(d, deudor.saldo), child: Text('Todo (${pesos(deudor.saldo)})')),
      ],
    ),
  );
  if (valor == null || valor <= 0) return false;
  await repo.registrar(
      tipo: TipoMovimiento.abono, valor: valor > deudor.saldo ? deudor.saldo : valor, clienteNombre: deudor.nombre);
  return true;
}
