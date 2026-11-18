import 'package:caporal/datos/biometria.dart';
import 'package:caporal/sincronizacion/sesion.dart';
import 'package:caporal/ui/cuenta/pantalla_pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Huella de mentira: responde lo que se le indique.
class _HuellaFalsa extends Biometria {
  final bool respuesta;
  int pedidas = 0;
  _HuellaFalsa(this.respuesta);

  @override
  Future<bool> disponible() async => true;

  @override
  Future<bool> verificar(String motivo) async {
    pedidas++;
    return respuesta;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
      }
      return null;
    });
  });

  test('sin PIN no se puede activar la huella, y quitar el PIN la apaga', () async {
    final sesion = Sesion();
    await sesion.cargar();
    await sesion.cambiarHuella(true);
    expect(sesion.usaHuella, isFalse);

    await sesion.guardarPin('1234');
    await sesion.cambiarHuella(true);
    expect(sesion.usaHuella, isTrue);
    final otra = Sesion();
    await otra.cargar();
    expect(otra.usaHuella, isTrue); // queda guardado

    await sesion.quitarPin();
    expect(sesion.usaHuella, isFalse);
  });

  Future<Sesion> conPinYHuella() async {
    final sesion = Sesion();
    await sesion.cargar();
    await sesion.guardarPin('1234');
    await sesion.cambiarHuella(true);
    sesion.desbloqueada = false;
    return sesion;
  }

  Widget pantalla(Sesion sesion, Biometria huella) => MultiProvider(
        providers: [ChangeNotifierProvider.value(value: sesion), Provider.value(value: huella)],
        child: const MaterialApp(home: PantallaPin()),
      );

  testWidgets('con huella activada, abre la app sin escribir el PIN', (t) async {
    final sesion = await t.runAsync(conPinYHuella);
    final huella = _HuellaFalsa(true);
    await t.pumpWidget(pantalla(sesion!, huella));
    await t.pumpAndSettle();
    expect(huella.pedidas, 1);
    expect(sesion.desbloqueada, isTrue);
  });

  testWidgets('si la huella no coincide, queda el PIN y el botón para reintentar', (t) async {
    final sesion = await t.runAsync(conPinYHuella);
    await t.pumpWidget(pantalla(sesion!, _HuellaFalsa(false)));
    await t.pumpAndSettle();
    expect(sesion.desbloqueada, isFalse);
    expect(find.text('Escriba su PIN o intente de nuevo con la huella'), findsOneWidget);
    expect(find.text('Usar huella o Face ID'), findsOneWidget);
  });
}
