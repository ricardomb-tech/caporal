import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Pide al servidor el código de recuperación por mensaje de texto.
/// Cambiar la clave con ese código está en [Sesion.restablecerClave], porque deja la sesión abierta.
class ClienteRecuperacion {
  /// Devuelve null si el código salió, o el mensaje de error para mostrar.
  Future<String?> pedirCodigo(String celular) async {
    try {
      final r = await http
          .post(Uri.parse('$apiUrl/api/v1/auth/recuperar/codigo'),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode({'celular': celular}))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 202) return null;
      final datos = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      return (datos['detail'] ?? 'No pudimos enviar el código. Intente de nuevo.') as String;
    } catch (_) {
      return 'No hay conexión. Para recuperar la clave necesita Internet.';
    }
  }
}
