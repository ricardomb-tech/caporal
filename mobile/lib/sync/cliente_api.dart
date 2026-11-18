import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class RespuestaApi {
  final int estado;
  final Map<String, dynamic> cuerpo;
  const RespuestaApi(this.estado, this.cuerpo);
}

/// POST con token a la API. Lanza si no hay red o se agota el tiempo: quien llama reintenta después.
class ClienteApi {
  Future<RespuestaApi> post(String ruta, String token, Map<String, Object?> cuerpo) async {
    final r = await http
        .post(Uri.parse('$apiUrl$ruta'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode(cuerpo))
        .timeout(const Duration(seconds: 20));
    final datos = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    return RespuestaApi(r.statusCode, datos);
  }

  /// GET con token a la API. Lanza si no hay red o se agota el tiempo.
  Future<RespuestaApi> get(String ruta, String token) async {
    final r = await http
        .get(Uri.parse('$apiUrl$ruta'), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 30));
    final datos = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    return RespuestaApi(r.statusCode, datos);
  }
}
