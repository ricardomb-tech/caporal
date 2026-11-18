import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../datos/inventario.dart';
import '../datos/repositorio.dart';
import 'cliente_api.dart';
import 'envio.dart';
import 'envio_catalogo.dart';
import 'envio_movimientos.dart';
import 'restauracion.dart';
import 'sincronizacion_perfil.dart';
import 'sesion.dart';

/// Envía la cola de salida cuando hay señal. Es seguro reintentar:
/// el servidor reconoce por id lo que ya recibió, así que nada se duplica.
class Sincronizador extends ChangeNotifier {
  final Repositorio repo;
  final Inventario inventario;
  final Sesion sesion;
  late final List<Envio> _envios;
  late final Restauracion _restauracion;
  late final SincronizacionPerfil _perfil;
  StreamSubscription<List<ConnectivityResult>>? _escucha;
  Timer? _reloj;
  bool _enCurso = false;

  bool conSenal = true;
  int pendientes = 0;

  /// Mientras trae del servidor los datos de la cuenta (teléfono nuevo o app reinstalada).
  bool restaurando = false;

  /// Cada cuánto se consulta lo que anotaron otros celulares de la misma cuenta.
  static const cadaCuantoPonerseAlDia = Duration(minutes: 1);
  DateTime? _ultimaPuestaAlDia;

  bool get _tocaPonerseAlDia =>
      _ultimaPuestaAlDia == null || DateTime.now().difference(_ultimaPuestaAlDia!) >= cadaCuantoPonerseAlDia;
  bool huboError = false;
  DateTime? ultimaVez;

  Sincronizador(this.repo, this.inventario, this.sesion) {
    final api = ClienteApi();
    // El catálogo va primero: así el servidor conoce el producto antes de recibir sus ventas.
    _envios = [EnvioCatalogo(inventario, repo.cola, api), EnvioMovimientos(repo, api)];
    _restauracion = Restauracion(repo.db, api);
    _perfil = SincronizacionPerfil(sesion, api);
  }

  Future<void> iniciar() async {
    _actualizarSenal(await Connectivity().checkConnectivity());
    _escucha = Connectivity().onConnectivityChanged.listen((r) {
      _actualizarSenal(r);
      if (conSenal) sincronizar();
    });
    // Cada minuto: respaldo por si el sistema no avisa el cambio de red, y traer lo de otros celulares.
    _reloj = Timer.periodic(const Duration(minutes: 1), (_) => sincronizar());
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
    if (sesion.restaurado && pendientes == 0 && !sesion.perfilPendiente && !_tocaPonerseAlDia) return;
    _enCurso = true;
    try {
      // Primero se trae lo que hay en el servidor: así un teléfono nuevo o reinstalado recupera todo.
      if (!sesion.restaurado && !await _restaurar()) return;
      // El perfil va aparte: si falla, las ventas y fiados se siguen enviando igual.
      await _conRenovacion(_perfil.enviar);
      for (final envio in _envios) {
        if (!await _vaciar(envio)) break;
      }
      // Después de enviar, se trae lo que anotaron los otros celulares de la cuenta.
      if (_tocaPonerseAlDia) await _ponerseAlDia();
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
      if (!await _conRenovacion(_perfil.traer)) {
        huboError = conSenal;
        return false;
      }
      final r = await _traerCambios(desde: null);
      if (r.resultado != ResultadoRestauracion.restaurado) {
        huboError = conSenal;
        return false;
      }
      await sesion.marcarRestaurado();
      return true;
    } finally {
      restaurando = false;
      notifyListeners();
    }
  }

  /// Trae los cambios de la cuenta desde [desde] (null: todo), guarda hasta dónde quedó y avisa a las pantallas.
  Future<PuestaAlDia> _traerCambios({required String? desde}) async {
    var r = await _restauracion.ejecutar(sesion.token!, desde: desde);
    if (r.resultado == ResultadoRestauracion.sesionVencida && await sesion.renovar()) {
      r = await _restauracion.ejecutar(sesion.token!, desde: desde);
    }
    if (r.resultado == ResultadoRestauracion.restaurado) {
      await sesion.guardarCambiosHasta(r.hasta);
      _ultimaPuestaAlDia = DateTime.now();
      ultimaVez = DateTime.now();
      if (r.recibidos > 0) {
        repo.avisarCambio();
        inventario.avisarCambio();
      }
    }
    return r;
  }

  /// Lo nuevo de otros celulares (y su perfil, por si cambiaron la llave Bre-B). Un error no frena nada:
  /// se intenta de nuevo en la siguiente vuelta.
  Future<void> _ponerseAlDia() async {
    await _traerCambios(desde: sesion.cambiosHasta);
    if (!sesion.perfilPendiente) await _conRenovacion(_perfil.traer);
  }

  /// Ejecuta un paso; si el acceso venció lo renueva y lo intenta una vez más. False si hay que parar.
  Future<bool> _conRenovacion(Future<ResultadoEnvio> Function(String token) paso) async {
    var r = await paso(sesion.token!);
    if (r == ResultadoEnvio.sesionVencida && await sesion.renovar()) r = await paso(sesion.token!);
    if (r == ResultadoEnvio.enviado) ultimaVez = DateTime.now();
    return r == ResultadoEnvio.enviado || r == ResultadoEnvio.nada;
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
