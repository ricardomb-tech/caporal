import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/inventario.dart';
import '../data/repositorio.dart';
import 'cliente_api.dart';
import 'envio.dart';
import 'envio_catalogo.dart';
import 'envio_movimientos.dart';
import 'sesion.dart';

/// Envía la cola de salida cuando hay señal. Es seguro reintentar:
/// el servidor reconoce por id lo que ya recibió, así que nada se duplica.
class Sincronizador extends ChangeNotifier {
  final Repositorio repo;
  final Inventario inventario;
  final Sesion sesion;
  late final List<Envio> _envios;
  StreamSubscription<List<ConnectivityResult>>? _escucha;
  Timer? _reloj;
  bool _enCurso = false;

  bool conSenal = true;
  int pendientes = 0;
  bool huboError = false;
  DateTime? ultimaVez;

  Sincronizador(this.repo, this.inventario, this.sesion) {
    final api = ClienteApi();
    // El catálogo va primero: así el servidor conoce el producto antes de recibir sus ventas.
    _envios = [EnvioCatalogo(inventario, repo.cola, api), EnvioMovimientos(repo, api)];
  }

  Future<void> iniciar() async {
    _actualizarSenal(await Connectivity().checkConnectivity());
    _escucha = Connectivity().onConnectivityChanged.listen((r) {
      _actualizarSenal(r);
      if (conSenal) sincronizar();
    });
    // Respaldo por si el sistema no avisa el cambio de red.
    _reloj = Timer.periodic(const Duration(minutes: 2), (_) => sincronizar());
    repo.addListener(sincronizar);
    inventario.addListener(sincronizar);
    await sincronizar();
  }

  void _actualizarSenal(List<ConnectivityResult> r) {
    conSenal = r.any((c) => c != ConnectivityResult.none);
    notifyListeners();
  }

  Future<void> sincronizar() async {
    pendientes = await repo.cantidadPendiente();
    notifyListeners();
    if (_enCurso || !conSenal || sesion.token == null || pendientes == 0) return;
    _enCurso = true;
    try {
      for (final envio in _envios) {
        if (!await _vaciar(envio)) break;
      }
    } finally {
      _enCurso = false;
      pendientes = await repo.cantidadPendiente();
      notifyListeners();
    }
  }

  /// Envía lotes de un tipo hasta que no quede nada. Devuelve false si hay que parar.
  Future<bool> _vaciar(Envio envio) async {
    while (true) {
      switch (await envio.enviarLote(sesion.token!)) {
        case ResultadoEnvio.nada:
          return true;
        case ResultadoEnvio.enviado:
          ultimaVez = DateTime.now();
          huboError = false;
        case ResultadoEnvio.sesionVencida:
          // El acceso dura poco: se renueva solo y se sigue enviando. Si no se puede, se espera.
          if (await sesion.renovar()) continue;
          return false;
        case ResultadoEnvio.error:
          // Sin red o error del servidor: lo pendiente sigue en la cola y se reintenta después.
          huboError = conSenal;
          return false;
      }
    }
  }

  @override
  void dispose() {
    repo.removeListener(sincronizar);
    inventario.removeListener(sincronizar);
    _escucha?.cancel();
    _reloj?.cancel();
    super.dispose();
  }
}
