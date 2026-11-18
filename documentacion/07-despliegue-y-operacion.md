# 7. Despliegue y operación

## Servidor

La guía paso a paso está en [`deploy/vps/README.md`](../deploy/vps/README.md). En resumen:

| Pieza | Cómo |
|---|---|
| Contenedores | `deploy/vps/docker-compose.yml`: PostgreSQL 16 y la API, sin puertos públicos, logs acotados |
| HTTPS | Caddy delante, con certificado Let's Encrypt, TLS 1.2 y 1.3 y HSTS |
| Usuario | `despliegue`, sin privilegios de root, en `/opt/caporal` |
| Secretos | `deploy/vps/.env` con permisos 600; ejemplo en `.env.example` (sin valores reales) |
| Actualizar | `ssh despliegue@<servidor> /opt/caporal/deploy/vps/desplegar.sh` (trae de GitHub, reconstruye y espera a que esté sana) |
| Migraciones | Flyway las aplica solo al arrancar la API |
| Respaldos | Diarios a las 3:15 UTC, cifrados con `age`; la llave privada está fuera del servidor; 14 días |
| Restauración | `deploy/vps/probar-restauracion.sh` la prueba en una base temporal; mensual |
| Vigilancia | `deploy/vps/vigilar.sh` cada 5 minutos: salud, HTTPS y disco; reinicia la API si no responde |
| Política de privacidad | Pública en `https://<servidor>/privacidad`; es la dirección que se pone en App Store Connect y Google Play |
| Eventos de seguridad | `docker compose logs api | grep 'evento='` |

En local basta `docker compose up --build` en la raíz (ver el [README principal](../README.md)).

## App

| Plataforma | Mínimo | Compilar | Publicar |
|---|---|---|---|
| Android | 12 (API 31) | `flutter build apk --release --dart-define=API_URL=<api>` para instalar a mano; `flutter build appbundle ...` para Google Play | Falta la llave de firma propia (hoy se firma con la de pruebas) y la cuenta de Google Play Console |
| iOS | 16.0 | `flutter build ios --release --dart-define=API_URL=<api>` y archivar en Xcode | Subida a App Store Connect como "Caporal Casanare" para TestFlight; incluye el manifiesto de privacidad `PrivacyInfo.xcprivacy` |

Variables al compilar: `API_URL` (dirección de la API) y `SOPORTE_WHATSAPP` (número de soporte de Ayuda).

Antes de cada versión:

1. `cd backend && mvn verify` y `cd mobile && flutter analyze && flutter test`.
2. Subir el número de compilación en `mobile/pubspec.yaml` (`version: X.Y.Z+N`).
3. Desplegar la API si cambió y después publicar la app.
4. Correr las pruebas manuales PM-04 a PM-06 en un celular.

## Licencias

La app y la API usan solo dependencias con licencias permisivas (Apache 2.0, MIT, BSD y la licencia de PostgreSQL). La licencia del código de Caporal está por definir con el equipo (recomendada: Apache 2.0).
