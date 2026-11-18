# Caporal

Las cuentas de su negocio, fáciles y sin señal. App móvil para micronegocios de Casanare: registrar ventas, gastos y fiados en tres toques, cobrar lo fiado, llevar el inventario y ver cuánto ganó hoy, con o sin Internet.

Proyecto de la convocatoria CreaTIC Casanare (Gobernación de Casanare, 2026). Equipo: caporal_tech, Yopal.

## Requisitos de la convocatoria

| Requisito | Cómo se cumple | Dónde verlo |
|---|---|---|
| Multiplataforma | Una sola app en Flutter para Android e iOS | `mobile/` |
| Compatibilidad | Android 12 (API 31) o superior; iOS 16 o superior | `mobile/android/app/build.gradle.kts` (`minSdk = 31`), `mobile/ios/Podfile` |
| Modo offline | Base local cifrada (SQLCipher), cola de salida única, reintentos idempotentes y restauración completa al reinstalar o cambiar de celular | `mobile/lib/datos/`, `mobile/lib/sincronizacion/`, ADR-06 en `documentacion/decisiones-de-arquitectura.md` |
| Seguridad | HTTPS con TLS 1.2 o 1.3, claves con Argon2id, sesión corta con renovación revocable, aislamiento por negocio, límites de solicitudes, respaldos cifrados | `documentacion/seguridad/auditoria-2026-11-17.md` |
| En español y accesible | Toda la interfaz en español de Colombia, formularios guiados con ejemplos, botones grandes y zonas tocables anunciadas al lector de pantalla | `mobile/lib/ui/`, `mobile/test/accesibilidad_test.dart` |
| Código documentado | Comentarios en el código, decisiones y documentación en `documentacion/`, instrucciones de despliegue, dependencias con licencias permisivas | Este archivo, `deploy/vps/README.md` |

## Qué hace la app

- **Vendí, Gasté y Fié:** valor en un teclado grande o tocando productos; varios productos se suman solos.
- **Le deben:** saldo por cliente, recordatorio de cobro por WhatsApp con la llave Bre-B y registro del pago (efectivo, Bre-B o transferencia) con número y foto del comprobante, aviso de comprobante repetido y verificación de que la plata llegó.
- **Inventario:** cada venta descuenta, cada pedido suma, conteos y avisos de lo que se acaba.
- **Resumen, historial y corrección:** nada se borra; un error se corrige con un movimiento de reverso.
- **Privacidad (Ley 1581):** autorización al registrarse, exportar y borrar la cuenta; el celular de los clientes no sale del teléfono.
- **Sin señal:** todo se guarda primero en el celular y se envía solo al volver la conexión. Al entrar en un celular nuevo o con la app reinstalada, se trae todo del servidor.

## Partes

```
backend/   API Spring Boot 4 (Java 21), PostgreSQL 16, migraciones Flyway
mobile/    App Flutter (Android e iOS)
deploy/    Despliegue en un servidor con Docker
documentacion/  Casos de uso, pruebas, modelo de datos, API, arquitectura y seguridad
```

API principal: registro e ingreso (`/api/v1/auth/*`), envío de movimientos (`/api/v1/sync/push`), catálogo e inventario (`/api/v1/sync/catalogo`), respaldo para restaurar (`/api/v1/sync/respaldo`) y borrado de cuenta (`DELETE /api/v1/cuenta`).

## Levantar la API en local

```bash
cp .env.example .env      # y cambie las claves
docker compose up --build
# Salud: http://localhost:8080/actuator/health
# Documentación (solo en local): http://localhost:8080/swagger-ui.html
```

Pruebas: `cd backend && mvn verify` (usa H2 en memoria; no necesita PostgreSQL).

## Correr la app

Requiere Flutter estable y, para iOS, Xcode.

```bash
cd mobile
flutter pub get
flutter test
flutter run --dart-define=API_URL=http://10.0.2.2:8080        # emulador Android con la API local
flutter run --dart-define=API_URL=http://localhost:8080       # simulador iOS con la API local
```

Contra un servidor desplegado: `--dart-define=API_URL=https://<dominio-de-su-api>`. El número de soporte de Ayuda se define con `--dart-define=SOPORTE_WHATSAPP=57...`.

Compilar para instalar a mano:

```bash
flutter build apk --release --dart-define=API_URL=https://<dominio-de-su-api>
flutter build ios --release --dart-define=API_URL=https://<dominio-de-su-api>
```

Para Google Play hace falta una llave de firma propia (hoy el APK se firma con la llave de pruebas) y generar `flutter build appbundle`.

## Desplegar el servidor

Ver `deploy/vps/README.md`: Docker Compose detrás de un proxy con HTTPS, usuario sin privilegios, respaldos diarios cifrados, prueba de restauración y vigilancia cada 5 minutos.

## Prueba en modo avión

1. Cree la cuenta con Internet.
2. Active el modo avión. Registre ventas, gastos y fiados; cierre y abra la app: todo sigue ahí.
3. Desactive el modo avión: el aviso pasa de "Sin señal" a "Copia de seguridad al día" y los movimientos llegan al servidor una sola vez, aunque el envío se reintente.
4. Borre la app, instálela de nuevo y entre con el mismo celular y clave: vuelven todos los datos que ya estaban "al día".

## Pendiente

- Llave de firma para Google Play y publicación en Google Play y App Store.
- Tablero de la Gobernación con datos agregados y anónimos.
- Recuperar la clave sin soporte humano (hoy se atiende desde Ayuda).
- Integración continua en GitHub (bloqueada por el pago de la cuenta).

## Derechos

© 2026 caporal_tech. Licencia por definir. Las dependencias usan licencias permisivas (BSD, MIT, Apache 2.0, PostgreSQL).
