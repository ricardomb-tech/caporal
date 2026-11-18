import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../datos/cola_salida.dart';
import '../datos/inventario.dart';
import '../datos/repositorio.dart';
import '../dominio/avisos.dart';
import 'notificador.dart';

/// Los avisos del dueño: si los quiere, cuáles y con cuánto detalle. Cada vez que cambian los datos
/// (una venta, un pago, un pedido) vuelve a calcular qué avisar y reprograma los avisos del celular.
class Avisos extends ChangeNotifier {
  final Repositorio repo;
  final Inventario inventario;
  final ColaSalida cola;
  final Notificador notificador;
  final FlutterSecureStorage _almacen;
  Avisos(this.repo, this.inventario, this.cola, this.notificador, {FlutterSecureStorage? almacen})
      : _almacen = almacen ?? const FlutterSecureStorage();

  static const _claveActivos = 'caporal_avisos';
  static const _claveDetalle = 'caporal_avisos_detalle';

  /// Si el dueño aceptó recibir avisos (y el sistema dio permiso).
  bool encendidos = false;
  Set<TipoAviso> activos = TipoAviso.values.toSet();

  /// Mostrar nombres y valores en el aviso. Apagado por defecto: el aviso se ve con el celular bloqueado.
  bool conDetalle = false;

  Timer? _espera;

  Future<void> cargar() async {
    final guardado = await _almacen.read(key: _claveActivos);
    encendidos = guardado != null && guardado.isNotEmpty;
    if (encendidos) {
      activos = {for (final n in guardado!.split(',')) ...TipoAviso.values.where((t) => t.name == n)};
    }
    conDetalle = await _almacen.read(key: _claveDetalle) == '1';
    repo.addListener(_programarPronto);
    inventario.addListener(_programarPronto);
    notifyListeners();
    if (encendidos) await reprogramar();
  }

  /// Enciende los avisos: pide permiso al sistema. Devuelve false si el dueño no lo dio.
  Future<bool> encender() async {
    if (!await notificador.pedirPermiso()) return false;
    encendidos = true;
    await _guardar();
    await reprogramar();
    return true;
  }

  Future<void> apagar() async {
    encendidos = false;
    await _almacen.write(key: _claveActivos, value: '');
    await notificador.programar(const []);
    notifyListeners();
  }

  Future<void> cambiar(TipoAviso tipo, bool activo) async {
    activo ? activos.add(tipo) : activos.remove(tipo);
    await _guardar();
    await reprogramar();
  }

  Future<void> cambiarDetalle(bool valor) async {
    conDetalle = valor;
    await _almacen.write(key: _claveDetalle, value: valor ? '1' : '0');
    await reprogramar();
  }

  Future<void> _guardar() async {
    // Encendidos sin ningún tipo se guarda como "-" para no confundirlo con apagados ("").
    await _almacen.write(key: _claveActivos, value: activos.isEmpty ? '-' : activos.map((t) => t.name).join(','));
    notifyListeners();
  }

  /// Muchos cambios seguidos (una venta toca varias tablas) se agrupan en una sola reprogramación.
  void _programarPronto() {
    if (!encendidos) return;
    _espera?.cancel();
    _espera = Timer(const Duration(seconds: 2), reprogramar);
  }

  Future<EstadoParaAvisos> estado() async {
    final deudores = await repo.deudores();
    final proveedores = await repo.deudasConProveedores();
    final productos = [
      for (final p in await inventario.productos())
        if (p.controlaStock) (p.nombre, p.stock)
    ];
    final pendientes = await cola.pendientes(TipoCola.movimiento, limite: 1);
    return EstadoParaAvisos(
      deudores: [for (final d in deudores) (d.nombre, d.saldo, d.desde)],
      proveedores: [for (final d in proveedores) (d.nombre, d.saldo, d.desde)],
      productos: productos,
      sinCopia: await cola.cantidad(),
      sinCopiaDesde: pendientes.isEmpty
          ? null
          : DateTime.fromMicrosecondsSinceEpoch(pendientes.first.version, isUtc: true).toLocal(),
    );
  }

  Future<void> reprogramar() async {
    if (!encendidos) return;
    final plan = PlanAvisos.planear(await estado(), ahora: DateTime.now(), activos: activos, conDetalle: conDetalle);
    await notificador.programar(plan);
  }

  @override
  void dispose() {
    _espera?.cancel();
    repo.removeListener(_programarPronto);
    inventario.removeListener(_programarPronto);
    super.dispose();
  }
}
