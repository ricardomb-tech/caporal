import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

/// Sesión del negocio y datos del perfil. Todo vive en el almacén seguro del sistema
/// (Keystore en Android, Keychain en iOS).
class Sesion extends ChangeNotifier {
  static const _almacen = FlutterSecureStorage();
  static const _claveToken = 'caporal_token';
  static const _claveNegocio = 'caporal_negocio';
  static const _clavePerfil = 'caporal_perfil';
  static const _clavePin = 'caporal_pin';
  static const _claveBienvenida = 'caporal_bienvenida';

  String? token;
  String? nombreNegocio;

  // Perfil: se guarda en el teléfono; el servidor solo conoce celular, negocio y municipio.
  String? nombrePersona;
  String? correo;
  String? celular;
  String? tipoNegocio;
  String? municipio;
  String? llaveBreB;
  bool compartirCifras = false;

  bool bienvenidaVista = false;
  bool _tienePin = false;
  bool desbloqueada = false;

  bool get activa => nombreNegocio != null;
  bool get tienePin => _tienePin;

  Future<void> cargar() async {
    token = await _almacen.read(key: _claveToken);
    nombreNegocio = await _almacen.read(key: _claveNegocio);
    bienvenidaVista = await _almacen.read(key: _claveBienvenida) == '1';
    _tienePin = await _almacen.read(key: _clavePin) != null;
    final perfil = await _almacen.read(key: _clavePerfil);
    if (perfil != null) {
      final p = jsonDecode(perfil) as Map<String, dynamic>;
      nombrePersona = p['nombre'] as String?;
      correo = p['correo'] as String?;
      celular = p['celular'] as String?;
      tipoNegocio = p['tipo'] as String?;
      municipio = p['municipio'] as String?;
      llaveBreB = p['llave'] as String?;
      compartirCifras = p['cifras'] == true;
    }
    notifyListeners();
  }

  Future<void> _guardarPerfil() => _almacen.write(
      key: _clavePerfil,
      value: jsonEncode({
        'nombre': nombrePersona,
        'correo': correo,
        'celular': celular,
        'tipo': tipoNegocio,
        'municipio': municipio,
        'llave': llaveBreB,
        'cifras': compartirCifras,
      }));

  Future<void> marcarBienvenida() async {
    bienvenidaVista = true;
    await _almacen.write(key: _claveBienvenida, value: '1');
    notifyListeners();
  }

  Future<void> guardarDatosPersonales({required String nombre, required String correoNuevo}) async {
    nombrePersona = nombre;
    correo = correoNuevo.isEmpty ? null : correoNuevo;
    await _guardarPerfil();
    notifyListeners();
  }

  Future<void> guardarNegocio({required String nombre, String? tipo, required String municipioNuevo, String? llave}) async {
    nombreNegocio = nombre;
    tipoNegocio = tipo;
    municipio = municipioNuevo;
    llaveBreB = (llave == null || llave.isEmpty) ? null : llave;
    await _almacen.write(key: _claveNegocio, value: nombre);
    await _guardarPerfil();
    notifyListeners();
  }

  Future<void> cambiarCompartirCifras(bool valor) async {
    compartirCifras = valor;
    await _guardarPerfil();
    notifyListeners();
  }

  /// Devuelve null si salió bien, o el mensaje de error para mostrar.
  Future<String?> registrar({
    required String celular,
    required String nombreNegocio,
    required String municipio,
    required String clave,
    required bool aceptaDatos,
    String? nombrePersona,
    String? correo,
    String? tipoNegocio,
    bool compartirCifras = false,
  }) async {
    final error = await _enviar('/api/v1/auth/registro', {
      'celular': celular,
      'nombreNegocio': nombreNegocio,
      'municipio': municipio,
      'clave': clave,
      'aceptaDatos': aceptaDatos,
    });
    if (error != null) return error;
    this.celular = celular;
    this.municipio = municipio;
    this.nombrePersona = nombrePersona;
    this.correo = (correo == null || correo.isEmpty) ? null : correo;
    this.tipoNegocio = tipoNegocio;
    this.compartirCifras = compartirCifras;
    await _guardarPerfil();
    notifyListeners();
    return null;
  }

  Future<String?> ingresar(String celular, String clave) async {
    final error = await _enviar('/api/v1/auth/login', {'celular': celular, 'clave': clave});
    if (error == null) {
      this.celular = celular;
      await _guardarPerfil();
      notifyListeners();
    }
    return error;
  }

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
        desbloqueada = true;
        notifyListeners();
        return null;
      }
      return (datos['detail'] ?? datos['message'] ?? 'No pudimos entrar. Revise los datos e intente de nuevo.') as String;
    } catch (_) {
      return 'No hay conexión. Para crear la cuenta o entrar por primera vez necesita Internet.';
    }
  }

  // ---- PIN: candado de comodidad para que otra persona no abra las cuentas ----

  String _hash(String sal, String pin) => sha256.convert(utf8.encode('$sal$pin')).toString();

  Future<void> guardarPin(String pin) async {
    final azar = Random.secure();
    final sal = base64UrlEncode(List<int>.generate(12, (_) => azar.nextInt(256)));
    await _almacen.write(key: _clavePin, value: '$sal:${_hash(sal, pin)}');
    _tienePin = true;
    desbloqueada = true;
    notifyListeners();
  }

  Future<bool> verificarPin(String pin) async {
    final v = await _almacen.read(key: _clavePin);
    if (v == null) return true;
    final partes = v.split(':');
    final ok = _hash(partes[0], pin) == partes[1];
    if (ok) {
      desbloqueada = true;
      notifyListeners();
    }
    return ok;
  }

  Future<void> quitarPin() async {
    await _almacen.delete(key: _clavePin);
    _tienePin = false;
    notifyListeners();
  }

  /// Pide al servidor borrar la cuenta y los movimientos. Devuelve null si salió bien.
  Future<String?> borrarEnServidor() async {
    if (token == null) return 'Para borrar también la copia en el servidor, entre de nuevo con su celular y su clave.';
    try {
      final r = await http
          .delete(Uri.parse('$apiUrl/api/v1/cuenta'), headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 20));
      if (r.statusCode == 204 || r.statusCode == 200) return null;
      if (r.statusCode == 401) return 'Su sesión venció. Entre de nuevo para borrar sus datos.';
      return 'No pudimos borrar en este momento. Intente de nuevo.';
    } catch (_) {
      return 'Sin Internet no podemos borrar la copia del servidor. Conéctese e intente de nuevo.';
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
    desbloqueada = false;
    await _almacen.delete(key: _claveToken);
    await _almacen.delete(key: _claveNegocio);
    notifyListeners();
  }

  /// Borra además el perfil y el PIN (se usa al eliminar los datos).
  Future<void> olvidarTodo() async {
    await _almacen.delete(key: _clavePerfil);
    await _almacen.delete(key: _clavePin);
    nombrePersona = correo = celular = tipoNegocio = municipio = llaveBreB = null;
    compartirCifras = false;
    _tienePin = false;
    await cerrar();
  }
}
