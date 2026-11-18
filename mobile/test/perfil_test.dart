import 'package:caporal/sincronizacion/cliente_api.dart';
import 'package:caporal/sincronizacion/envio.dart';
import 'package:caporal/sincronizacion/sesion.dart';
import 'package:caporal/sincronizacion/sincronizacion_perfil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// API de mentira: guarda lo último que recibió y responde lo preparado.
class _ApiFalsa extends ClienteApi {
  RespuestaApi respuesta;
  Map<String, Object?>? enviado;
  _ApiFalsa(this.respuesta);

  @override
  Future<RespuestaApi> put(String ruta, String token, Map<String, Object?> cuerpo) async {
    enviado = cuerpo;
    return respuesta;
  }

  @override
  Future<RespuestaApi> get(String ruta, String token) async => respuesta;
}

Map<String, dynamic> _perfil(String negocio, String llave, String? en) => {
      'nombreNegocio': negocio,
      'municipio': 'Aguazul',
      'nombrePersona': 'Marta Pérez',
      'correo': null,
      'tipoNegocio': 'Tienda',
      'llaveBreB': llave,
      'compartirCifras': false,
      'modificadoEn': en,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Almacén seguro en memoria para las pruebas.
  final almacen = <String, String>{};
  setUp(() {
    almacen.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (llamada) async {
      final args = (llamada.arguments as Map?) ?? {};
      switch (llamada.method) {
        case 'write':
          almacen[args['key'] as String] = args['value'] as String;
        case 'read':
          return almacen[args['key']];
        case 'delete':
          almacen.remove(args['key']);
        case 'readAll':
          return almacen;
        case 'containsKey':
          return almacen.containsKey(args['key']);
      }
      return null;
    });
  });

  test('al reinstalar trae el negocio, la llave Bre-B y los datos de quien atiende', () async {
    final sesion = Sesion();
    await sesion.cargar();
    final api = _ApiFalsa(RespuestaApi(200, _perfil('Tienda La Esperanza', '3101234567', '2026-11-17T15:00:00.000Z')));
    expect(await SincronizacionPerfil(sesion, api).traer('t'), ResultadoEnvio.enviado);
    expect(sesion.nombreNegocio, 'Tienda La Esperanza');
    expect(sesion.llaveBreB, '3101234567');
    expect(sesion.municipio, 'Aguazul');
    expect(sesion.nombrePersona, 'Marta Pérez');
    expect(sesion.perfilPendiente, isFalse);

    // Y queda guardado en el teléfono: otra sesión lo lee.
    final otra = Sesion();
    await otra.cargar();
    expect(otra.llaveBreB, '3101234567');
  });

  test('cambiar el negocio lo deja pendiente y se envía con su fecha', () async {
    final sesion = Sesion();
    await sesion.cargar();
    await sesion.guardarNegocio(nombre: 'El Cacha', tipo: 'Tienda', municipioNuevo: 'Yopal', llave: 'cacha@breb');
    expect(sesion.perfilPendiente, isTrue);

    final enviado = sesion.perfilParaEnviar();
    final api = _ApiFalsa(RespuestaApi(200, {
      ..._perfil('El Cacha', 'cacha@breb', enviado['modificadoEn'] as String),
      'municipio': 'Yopal',
    }));
    expect(await SincronizacionPerfil(sesion, api).enviar('t'), ResultadoEnvio.enviado);
    expect(api.enviado!['llaveBreB'], 'cacha@breb');
    expect(sesion.perfilPendiente, isFalse);
  });

  test('un perfil del servidor más viejo no pisa el cambio hecho en el teléfono', () async {
    final sesion = Sesion();
    await sesion.cargar();
    await sesion.guardarNegocio(nombre: 'Nombre nuevo', municipioNuevo: 'Yopal', llave: 'llave-nueva');
    await sesion.aplicarPerfilDelServidor(_perfil('Nombre viejo', 'llave-vieja', '2020-01-01T00:00:00.000Z'));
    expect(sesion.nombreNegocio, 'Nombre nuevo');
    expect(sesion.llaveBreB, 'llave-nueva');
    expect(sesion.perfilPendiente, isTrue); // sigue esperando su envío
  });

  test('sin nada que enviar no llama al servidor', () async {
    final sesion = Sesion();
    await sesion.cargar();
    final api = _ApiFalsa(const RespuestaApi(500, {}));
    expect(await SincronizacionPerfil(sesion, api).enviar('t'), ResultadoEnvio.nada);
    expect(api.enviado, isNull);
  });
}
