# Caporal

Las cuentas de su negocio, fáciles y sin señal. App móvil para micronegocios de Casanare: registrar ventas, gastos y fiados en tres toques, cobrar lo fiado y ver cuánto ganó hoy, con o sin Internet.

Proyecto postulado a la convocatoria CreaTIC Casanare (Gobernación de Casanare, 2026).

## Estado

Esqueleto técnico en construcción. Lo que hay hoy:

| Parte | Qué incluye | Estado |
|---|---|---|
| `backend/` | API Spring Boot 3 (Java 21): registro e inicio de sesión con JWT, bloqueo por intentos fallidos, límite de solicitudes, sincronización idempotente (`/api/v1/sync/push` y `/pull`), borrado de cuenta y datos (`DELETE /api/v1/cuenta`, Ley 1581), migraciones Flyway, pruebas de integración | Escrito; se compila y prueba en la integración continua |
| `mobile/` | App Flutter: base local cifrada (SQLCipher), cola de salida, sincronización automática. Las 31 pantallas del diseño: splash y bienvenida, ingreso, registro en 3 pasos con autorización de datos, inicio con navegación flotante de vidrio, vender / gastar / fiar, confirmación, movimientos, detalle y corrección por reverso, le deben y cliente (cobro por WhatsApp, abonos), resumen semanal, productos, perfil, negocio, PIN, estado de envío, privacidad, eliminar datos y ayuda | Escrito; **no se ha compilado ni probado todavía** (se analiza y prueba en la integración continua) |
| `docker-compose.yml` | PostgreSQL 16 y la API en contenedores | Listo para levantar |
| `docs/` | Arquitectura y decisiones (ADR), controles de seguridad | Primer borrador |

Pendiente (hoja de ruta):

- Recuperar clave por código SMS: la pantalla existe, el envío del código necesita un proveedor de mensajes (el botón avisa que llega en la siguiente versión).
- Perfil, negocio y productos viven solo en el teléfono; falta sincronizarlos (último cambio por campo).
- Huella dactilar para entrar (hoy solo PIN de 4 números como candado de comodidad).
- Tablero de la Gobernación y publicación en tiendas.
- Carpetas Android/iOS: `flutter create .` (ver abajo). Para abrir WhatsApp en Android 11+ agregue en `AndroidManifest.xml` un bloque `<queries>` con `https` (guía de `url_launcher`). El número de soporte de Ayuda se define con `--dart-define=SOPORTE_WHATSAPP=57...`.

Diseño de pantallas: https://www.figma.com/design/CBmo1YifjYCRJZoBgvgbnz

## Cómo levantar la API

```bash
cp .env.example .env      # cambie las claves
docker compose up --build
# Salud:          http://localhost:8080/actuator/health
# Documentación:  http://localhost:8080/swagger-ui.html
```

Pruebas del backend: `cd backend && mvn verify` (usa H2 en memoria, no necesita PostgreSQL).

## Cómo correr la app

Requiere Flutter estable. La primera vez hay que generar las carpetas de plataforma:

```bash
cd mobile
flutter create . --platforms=android,ios --org co.caporal
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:8080   # emulador Android contra la API local
flutter test
```

## Prueba en modo avión

1. Cree la cuenta con Internet.
2. Active el modo avión. Registre ventas, gastos y fiados; cierre y abra la app: todo sigue ahí.
3. Desactive el modo avión: el aviso pasa de "Sin señal" a "Copia de seguridad al día" y los movimientos llegan al servidor una sola vez, aunque el envío se reintente.

## Estructura

```
backend/   API de sincronización (Spring Boot, PostgreSQL, Flyway)
mobile/    App Flutter offline-first
docs/      Arquitectura, decisiones y seguridad
```

## Derechos

© 2026 caporal_tech. Todos los derechos reservados. Las dependencias usan licencias permisivas (BSD, MIT, Apache 2.0, PostgreSQL); ver `docs/seguridad.md`.
