import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

/// Sesión del negocio. El token vive en el almacén seguro del sistema.
class Sesion extends ChangeNotifier {
  static const _almacen = FlutterSecureStorage();
  static const _claveToken = 'caporal_token';
  static const _claveNegocio = 'caporal_negocio';

  String? token;
  String? nombreNegocio;
  bool get activa => nombreNegocio != null;

  Future<void> cargar() async {
    token = await _almacen.read(key: _claveToken);
    nombreNegocio = await _almacen.read(key: _claveNegocio);
    notifyListeners();
  }

  /// Devuelve null si salió bien, o el mensaje de error para mostrar.
  Future<String?> registrar({
    required String celular,
    required String nombreNegocio,
    required String municipio,
    required String clave,
    required bool aceptaDatos,
  }) =>
      _enviar('/api/v1/auth/registro', {
        'celular': celular,
        'nombreNegocio': nombreNegocio,
        'municipio': municipio,
        'clave': clave,
        'aceptaDatos': aceptaDatos,
      });

  Future<String?> ingresar(String celular, String clave) =>
      _enviar('/api/v1/auth/login', {'celular': celular, 'clave': clave});

  Future<String?> _enviar(String ruta, Map<String, Object?> cuerpo) async {
    try {
      final r = await http
          .post(Uri.parse('$apiUrl$ruta'),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode(cuerpo))
          .timeout(const Duration(seconds: 15));
      final datos = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      if (r.statusCode == 200 || r.statusCode == 201) {
        token = datos['token'] as String;
        nombreNegocio = datos['nombreNegocio'] as String;
        await _almacen.write(key: _claveToken, value: token);
        await _almacen.write(key: _claveNegocio, value: nombreNegocio);
        notifyListeners();
        return null;
      }
      return (datos['detail'] ?? datos['message'] ?? 'No pudimos entrar. Revise los datos e intente de nuevo.') as String;
    } catch (_) {
      return 'No hay conexión. Para crear la cuenta o entrar por primera vez necesita Internet.';
    }
  }

  /// El token venció: se borra, pero el negocio sigue trabajando sin conexión.
  Future<void> tokenVencido() async {
    token = null;
    await _almacen.delete(key: _claveToken);
    notifyListeners();
  }

  Future<void> cerrar() async {
    token = null;
    nombreNegocio = null;
    await _almacen.delete(key: _claveToken);
    await _almacen.delete(key: _claveNegocio);
    notifyListeners();
  }
}
