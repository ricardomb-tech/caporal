import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../data/repositorio.dart';
import 'sesion.dart';

/// Envía la cola de salida cuando hay señal. Es seguro reintentar:
/// el servidor reconoce por id los movimientos que ya recibió.
class Sincronizador extends ChangeNotifier {
  final Repositorio repo;
  final Sesion sesion;
  StreamSubscription<List<ConnectivityResult>>? _escucha;
  Timer? _reloj;
  bool _enCurso = false;

  bool conSenal = true;
  int pendientes = 0;
  bool huboError = false;
  DateTime? ultimaVez;

  Sincronizador(this.repo, this.sesion);

  Future<void> iniciar() async {
    _actualizarSenal(await Connectivity().checkConnectivity());
    _escucha = Connectivity().onConnectivityChanged.listen((r) {
      _actualizarSenal(r);
      if (conSenal) sincronizar();
    });
    // Respaldo por si el sistema no avisa el cambio de red.
    _reloj = Timer.periodic(const Duration(minutes: 2), (_) => sincronizar());
    repo.addListener(sincronizar);
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
      while (true) {
        final lote = await repo.pendientesDeEnvio();
        if (lote.isEmpty) break;
        final ids = lote.map((m) => m.id);
        try {
          final r = await http
              .post(Uri.parse('$apiUrl/api/v1/sync/push'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ${sesion.token}',
                  },
                  body: jsonEncode({'movimientos': lote.map((m) => m.aJson()).toList()}))
              .timeout(const Duration(seconds: 20));
          if (r.statusCode == 200) {
            final datos = jsonDecode(r.body) as Map<String, dynamic>;
            await repo.marcarEnviados([
              ...(datos['aceptados'] as List).cast<String>(),
              ...(datos['duplicados'] as List).cast<String>(),
            ]);
            ultimaVez = DateTime.now();
            huboError = false;
          } else if (r.statusCode == 401) {
            await sesion.tokenVencido();
            break;
          } else {
            huboError = true;
            await repo.contarIntento(ids);
            break;
          }
        } catch (_) {
          // Sin red o tiempo agotado: los movimientos siguen en la cola y se reintenta después.
          huboError = conSenal;
          await repo.contarIntento(ids);
          break;
        }
      }
    } finally {
      _enCurso = false;
      pendientes = await repo.cantidadPendiente();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    repo.removeListener(sincronizar);
    _escucha?.cancel();
    _reloj?.cancel();
    super.dispose();
  }
}
