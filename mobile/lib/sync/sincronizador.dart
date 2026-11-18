import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/inventario.dart';
import '../data/repositorio.dart';
import 'cliente_api.dart';
import 'envio.dart';
import 'envio_catalogo.dart';
import 'envio_movimientos.dart';
import 'restauracion.dart';
import 'sesion.dart';

/// Envía la cola de salida cuando hay señal. Es seguro reintentar:
/// el servidor reconoce por id lo que ya recibió, así que nada se duplica.
class Sincronizador extends ChangeNotifier {
  final Repositorio repo;
  final Inventario inventario;
  final Sesion sesion;
  late final List<Envio> _envios;
  late final Restauracion _restauracion;
  StreamSubscription<List<ConnectivityResult>>? _escucha;
  Timer? _reloj;
  bool _enCurso = false;

  bool conSenal = true;
  int pendientes = 0;

  /// Mientras trae del servidor los datos de la cuenta (teléfono nuevo o app reinstalada).
  bool restaurando = false;
  bool huboError = false;
  DateTime? ultimaVez;

  Sincronizador(this.repo, this.inventario, this.sesion) {
    final api = ClienteApi();
    // El catálogo va primero: así el servidor conoce el producto antes de recibir sus ventas.
    _envios = [EnvioCatalogo(inventario, repo.cola, api), EnvioMovimientos(repo, api)];
    _restauracion = Restauracion(repo.db, api);
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
    // Al entrar con la cuenta se trae el respaldo enseguida, sin esperar otra anotación.
    sesion.addListener(sincronizar);
    await sincronizar();
  }

  void _actualizarSenal(List<ConnectivityResult> r) {
    conSenal = r.any((c) => c != ConnectivityResult.none);
    notifyListeners();
  }

  Future<void> sincronizar() async {
    pendientes = await repo.cantidadPendiente();
    notifyListeners();
    if (_enCurso || !conSenal || sesion.token == null) return;
    if (sesion.restaurado && pendientes == 0) return;
    _enCurso = true;
    try {
      // Primero se trae lo que hay en el servidor: así un teléfono nuevo o reinstalado recupera todo.
      if (!sesion.restaurado && !await _restaurar()) return;
      for (final envio in _envios) {
        if (!await _vaciar(envio)) break;
      }
    } finally {
      _enCurso = false;
      pendientes = await repo.cantidadPendiente();
      notifyListeners();
    }
  }

  /// Trae el respaldo de la cuenta. Devuelve false si hay que parar e intentarlo después.
  Future<bool> _restaurar() async {
    restaurando = true;
    notifyListeners();
    try {
      var resultado = await _restauracion.ejecutar(sesion.token!);
      if (resultado == ResultadoRestauracion.sesionVencida && await sesion.renovar()) {
        resultado = await _restauracion.ejecutar(sesion.token!);
      }
      if (resultado != ResultadoRestauracion.restaurado) {
        huboError = conSenal;
        return false;
      }
      await sesion.marcarRestaurado();
      ultimaVez = DateTime.now();
      repo.avisarCambio();
      inventario.avisarCambio();
      return true;
    } finally {
      restaurando = false;
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
    sesion.removeListener(sincronizar);
    _escucha?.cancel();
    _reloj?.cancel();
    super.dispose();
  }
}
