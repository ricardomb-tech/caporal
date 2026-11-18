/// Cliente que debe plata: cuánto y desde cuándo (su fiado vigente más antiguo).
class Deudor {
  final String nombre;
  final int saldo;
  final DateTime desde;
  const Deudor(this.nombre, this.saldo, this.desde);
}

/// Proveedor al que se le debe: cuánto y desde cuándo (su pedido fiado vigente más antiguo).
class DeudaConProveedor {
  final String nombre;
  final int saldo;
  final DateTime desde;
  const DeudaConProveedor(this.nombre, this.saldo, this.desde);
}

/// Ventas y gastos de un día, para el resumen semanal.
class ResumenDia {
  final DateTime dia;
  final int ventas;
  final int gastos;
  const ResumenDia(this.dia, this.ventas, this.gastos);
}

/// Lo de hoy en la pantalla de inicio: lo que vendió, lo que gastó y lo que ganó.
class ResumenHoy {
  final int ventas;
  final int gastos;
  const ResumenHoy(this.ventas, this.gastos);
  int get ganancia => ventas - gastos;
}
