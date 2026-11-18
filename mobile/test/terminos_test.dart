import 'dart:convert';

import 'package:caporal/dominio/terminos.dart';
import 'package:caporal/sincronizacion/sesion.dart';
import 'package:caporal/ui/cuenta/pantalla_aceptar_terminos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final almacen = <String, String>{};
  setUp(() {
    almacen.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (llamada) async {
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

  test('aceptar sin cuenta queda en el celular sin marcar el perfil para enviar', () async {
    final s = Sesion();
    await s.cargar();
    await s.aceptarTerminos(versionTerminos);
    expect(s.terminosVersion, versionTerminos);
    expect(s.perfilPendiente, isFalse, reason: 'Un perfil vacío no debe ganarle al del servidor al entrar');
    final otra = Sesion();
    await otra.cargar();
    expect(otra.terminosVersion, versionTerminos, reason: 'Se recuerda al abrir de nuevo, aun sin Internet');
  });

  test('con cuenta, la constancia viaja en el perfil', () async {
    final s = Sesion()..nombreNegocio = 'Tienda';
    await s.aceptarTerminos(versionTerminos);
    expect(s.perfilPendiente, isTrue);
    expect(s.perfilParaEnviar()['terminosVersion'], versionTerminos);
    expect(s.perfilParaEnviar()['terminosAceptadosEn'], isNotNull);
  });

  test('al entrar, se adopta la constancia del servidor o se envía la del celular si es más nueva', () async {
    final s = Sesion();
    await s.cargar();
    await s.aplicarPerfilDelServidor({
      'nombreNegocio': 'Tienda',
      'municipio': 'Yopal',
      'modificadoEn': '2026-11-18T10:00:00Z',
      'terminosVersion': versionTerminos,
      'terminosAceptadosEn': '2026-11-18T10:00:00Z',
    });
    expect(s.terminosVersion, versionTerminos);
    expect(s.perfilPendiente, isFalse);

    final otra = Sesion();
    await otra.cargar();
    await otra.aceptarTerminos(versionTerminos); // antes de entrar
    await otra.aplicarPerfilDelServidor(
        {'nombreNegocio': 'Tienda', 'municipio': 'Yopal', 'modificadoEn': '2026-11-01T10:00:00Z'});
    expect(otra.nombreNegocio, 'Tienda', reason: 'El perfil del servidor no se pierde');
    expect(otra.perfilPendiente, isTrue, reason: 'La constancia se envía al servidor');
    expect(jsonEncode(otra.perfilParaEnviar()), contains('"nombreNegocio":"Tienda"'));
  });

  testWidgets('no deja seguir sin aceptar los términos y autorizar los datos', (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final s = Sesion();
    await t.runAsync(s.cargar);
    await t
        .pumpWidget(ChangeNotifierProvider.value(value: s, child: const MaterialApp(home: PantallaAceptarTerminos())));
    await t.pumpAndSettle();
    FilledButton boton() => t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Aceptar y seguir'));
    expect(find.text('Antes de empezar'), findsOneWidget);
    expect(boton().onPressed, isNull);
    Future<void> marcar(int i) async {
      await t.ensureVisible(find.byType(Checkbox).at(i));
      await t.pumpAndSettle();
      await t.tap(find.byType(Checkbox).at(i));
      await t.pump();
    }

    await marcar(0);
    expect(boton().onPressed, isNull, reason: 'Falta autorizar los datos');
    await marcar(1);
    expect(boton().onPressed, isNotNull);
    await t.runAsync(() async {
      await t.tap(find.text('Aceptar y seguir'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    expect(s.terminosVersion, versionTerminos);
  });
}
