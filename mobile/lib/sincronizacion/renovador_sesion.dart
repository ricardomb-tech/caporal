import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

enum ResultadoRenovacion { renovada, rechazada, sinRed }

/// Par de tokens nuevo que entrega el servidor al renovar.
class TokensNuevos {
  final String acceso;
  final String renovacion;
  const TokensNuevos(this.acceso, this.renovacion);
}

/// Llamadas de red de la sesión renovable: pedir un par nuevo y cerrar la sesión en el servidor.
class RenovadorSesion {
  Future<(ResultadoRenovacion, TokensNuevos?)> renovar(String tokenRenovacion) async {
    try {
      final r = await http
          .post(Uri.parse('$apiUrl/api/v1/auth/renovar'),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode({'tokenRenovacion': tokenRenovacion}))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final d = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
        return (ResultadoRenovacion.renovada, TokensNuevos(d['token'] as String, d['tokenRenovacion'] as String));
      }
      // 401: el servidor ya no reconoce la sesión (cerrada, vencida o revocada por seguridad).
      if (r.statusCode == 401) return (ResultadoRenovacion.rechazada, null);
      return (ResultadoRenovacion.sinRed, null);
    } catch (_) {
      return (ResultadoRenovacion.sinRed, null);
    }
  }

  /// Avisa al servidor que esta sesión terminó. Si no hay red no pasa nada: el token igual se borra del teléfono.
  Future<void> salir(String tokenRenovacion) async {
    try {
      await http
          .post(Uri.parse('$apiUrl/api/v1/auth/salir'),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode({'tokenRenovacion': tokenRenovacion}))
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
