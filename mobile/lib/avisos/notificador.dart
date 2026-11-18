import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_datos;
import 'package:timezone/timezone.dart' as tz;

import '../dominio/avisos.dart';

/// Lo que los avisos necesitan del sistema. Se puede reemplazar en las pruebas.
abstract class Notificador {
  Future<void> iniciar();

  /// Pide permiso al sistema para mostrar avisos. True si quedó concedido.
  Future<bool> pedirPermiso();

  /// Reemplaza todos los avisos programados por estos.
  Future<void> programar(List<Aviso> avisos);
}

/// Avisos locales: los programa el mismo celular, sin Internet y sin enviar datos a ningún servidor.
class NotificadorLocal implements Notificador {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _listo = false;

  static const _canal = AndroidNotificationDetails(
    'caporal_avisos',
    'Avisos de Caporal',
    channelDescription: 'Cobros pendientes, productos por acabarse, pagos a proveedores y cierre del día',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    // En la pantalla bloqueada se ve el aviso, pero el texto completo solo al desbloquear.
    visibility: NotificationVisibility.private,
  );

  @override
  Future<void> iniciar() async {
    if (_listo) return;
    tz_datos.initializeTimeZones();
    // Colombia no cambia de hora en el año.
    tz.setLocalLocation(tz.getLocation('America/Bogota'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        // El permiso se pide solo cuando el dueño acepta recibir avisos, nunca al abrir la app.
        iOS: DarwinInitializationSettings(
            requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      ),
    );
    _listo = true;
  }

  @override
  Future<bool> pedirPermiso() async {
    await iniciar();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, sound: true) ?? false;
    return false;
  }

  @override
  Future<void> programar(List<Aviso> avisos) async {
    await iniciar();
    await _plugin.cancelAll();
    for (final a in avisos) {
      await _plugin.zonedSchedule(
        id: a.tipo.id,
        scheduledDate: tz.TZDateTime.from(a.cuando, tz.local),
        notificationDetails: const NotificationDetails(android: _canal, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: a.titulo,
        body: a.cuerpo,
        payload: a.tipo.name,
      );
    }
  }
}
