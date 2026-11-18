import 'package:caporal/avisos/avisos.dart';
import 'package:caporal/avisos/notificador.dart';
import 'package:caporal/datos/base_local.dart';
import 'package:caporal/datos/cola_salida.dart';
import 'package:caporal/datos/inventario.dart';
import 'package:caporal/datos/repositorio.dart';
import 'package:caporal/dominio/avisos.dart';
import 'package:caporal/dominio/movimiento.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _NotificadorFalso implements Notificador {
  bool permiso = true;
  List<Aviso> programados = [];
  @override
  Future<void> iniciar() async {}
  @override
  Future<bool> pedirPermiso() async => permiso;
  @override
  Future<void> programar(List<Aviso> avisos) async => programados = avisos;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ahora = DateTime(2026, 11, 18, 14, 0);
  final todos = TipoAviso.values.toSet();

  group('qué se avisa', () {
    test('cobros de más de 15 días, sin nombres ni valores por defecto, a las 9 del día siguiente', () {
      final e = EstadoParaAvisos(deudores: [
        ('Don Hernán', 21100, ahora.subtract(const Duration(days: 16))),
        ('José', 7400, ahora.subtract(const Duration(days: 2))),
      ]);
      final a = PlanAvisos.planear(e, ahora: ahora, activos: {TipoAviso.cobros}).single;
      expect(a.cuando, DateTime(2026, 11, 19, 9, 0));
      expect(a.cuerpo, contains('Un cliente le debe'));
      expect(a.cuerpo, isNot(contains('Hernán')));
      final conDetalle = PlanAvisos.planear(e, ahora: ahora, activos: {TipoAviso.cobros}, conDetalle: true).single;
      expect(conDetalle.cuerpo, contains('Don Hernán le debe \$ 21.100 hace 16 días'));
    });

    test('productos con 3 o menos, proveedores de más de 8 días y anotaciones sin copia', () {
      final e = EstadoParaAvisos(
        productos: [('Gaseosa', 2), ('Arroz', 30), ('Pan', 0)],
        proveedores: [('Postobón', 96000, ahora.subtract(const Duration(days: 9)))],
        sinCopia: 4,
        sinCopiaDesde: ahora.subtract(const Duration(days: 3)),
      );
      final planes = {for (final a in PlanAvisos.planear(e, ahora: ahora, activos: todos, conDetalle: true)) a.tipo: a};
      expect(planes[TipoAviso.agotados]!.cuerpo, 'Se está acabando: Pan (0) y Gaseosa (2).');
      expect(planes[TipoAviso.proveedores]!.cuerpo, contains('\$ 96.000 a Postobón'));
      expect(planes[TipoAviso.copia]!.cuerpo, contains('4 anotaciones sin copia'));
      expect(planes[TipoAviso.cierre]!.cuando, DateTime(2026, 11, 18, 19, 30),
          reason: 'Hoy, porque aún no son las 7:30');
    });

    test('sin nada pendiente solo queda el cierre del día, y nada si están apagados', () {
      expect(PlanAvisos.planear(const EstadoParaAvisos(), ahora: ahora, activos: todos).map((a) => a.tipo),
          [TipoAviso.cierre]);
      expect(PlanAvisos.planear(const EstadoParaAvisos(), ahora: ahora, activos: {}), isEmpty);
    });

    test('ningún aviso sale de noche', () {
      final tarde = DateTime(2026, 11, 18, 22, 0);
      final e = EstadoParaAvisos(
          productos: const [('Pan', 0)], deudores: [('A', 1, tarde.subtract(const Duration(days: 20)))]);
      for (final a in PlanAvisos.planear(e, ahora: tarde, activos: todos)) {
        expect(a.cuando.hour, inInclusiveRange(8, 19), reason: '$a');
      }
    });
  });

  group('en el celular', () {
    sqfliteFfiInit();
    final almacen = <String, String>{};
    late Database db;
    late Repositorio repo;
    late Inventario inv;
    late ColaSalida cola;
    late _NotificadorFalso notificador;

    setUp(() async {
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
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(version: BaseLocal.version, onCreate: BaseLocal.crear, singleInstance: false));
      cola = ColaSalida(db);
      inv = Inventario(db, 'tel-1', cola);
      repo = Repositorio(db, 'tel-1', cola, inv);
      notificador = _NotificadorFalso();
    });
    tearDown(() => db.close());

    test('apagados hasta que el dueño acepta; si el celular no da permiso, siguen apagados', () async {
      final avisos = Avisos(repo, inv, cola, notificador);
      await avisos.cargar();
      expect(avisos.encendidos, isFalse);
      notificador.permiso = false;
      expect(await avisos.encender(), isFalse);
      expect(avisos.encendidos, isFalse);
      notificador.permiso = true;
      expect(await avisos.encender(), isTrue);
      expect(notificador.programados.map((a) => a.tipo), contains(TipoAviso.cierre));
      avisos.dispose();
    });

    test('se recuerdan al abrir de nuevo la app, con los tipos elegidos', () async {
      final primera = Avisos(repo, inv, cola, notificador);
      await primera.cargar();
      await primera.encender();
      await primera.cambiar(TipoAviso.cierre, false);
      primera.dispose();
      final otra = Avisos(repo, inv, cola, notificador);
      await otra.cargar();
      expect(otra.encendidos, isTrue);
      expect(otra.activos.contains(TipoAviso.cierre), isFalse);
      await otra.apagar();
      expect(notificador.programados, isEmpty);
      otra.dispose();
    });

    test('un producto que se acaba aparece en el aviso al reprogramar', () async {
      final p = await inv.crearProducto(nombre: 'Gaseosa', precio: 2500, stockInicial: 3);
      await repo.registrar(tipo: TipoMovimiento.venta, valor: 2500);
      final avisos = Avisos(repo, inv, cola, notificador);
      await avisos.cargar();
      await avisos.encender();
      expect(notificador.programados.map((a) => a.tipo), contains(TipoAviso.agotados));
      expect(p.nombre, 'Gaseosa');
      avisos.dispose();
    });
  });
}
