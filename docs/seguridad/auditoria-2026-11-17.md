# Auditoría de seguridad — Caporal

- **Fecha:** 17 de noviembre de 2026 · **Commit:** `2bab68f` · **Entorno:** API pública `https://caporal.2.25.187.25.sslip.io` (VPS de pruebas) y repositorio.
- **Método:** guía "27 controles de seguridad" (fase 1: auditar sin modificar) y referencia a ISO/IEC 27001:2022 (Anexo A) y SOC 2 (Trust Services Criteria). Cada estado se basa en una prueba ejecutada o en el código citado; lo que no se probó dice **NO VERIFICADO**.
- **Alcance:** API Spring Boot, app Flutter, despliegue Docker y VPS. Es una revisión técnica, **no una certificación**: ISO 27001 y SOC 2 exigen además gestión de riesgos, políticas, evidencias en el tiempo y auditoría externa (ver §4).

## 1. Resumen

| Estado | Cantidad |
|---|---|
| OK verificado | 13 |
| FALLA / parcial | 8 |
| No aplica (con motivo) | 6 |
| No verificado | 1 |

Riesgos más importantes: **Spring Boot 3.3.5 sin soporte** (dependencias con vulnerabilidades corregidas en versiones nuevas), **respaldos en el mismo servidor y sin cifrar**, **sin monitoreo ni alertas**, **token de Twilio pegado en un chat** (rotar) y **sesión de 60 minutos sin renovación**, que además frena la sincronización.

## 2. Los 27 controles

| # | Control | Estado | Riesgo | Evidencia | Corrección propuesta |
|---|---|---|---|---|---|
| 01 | Autenticación real en el servidor | OK | — | Sin token: `/api/v1/sync/pull`, `/sync/push`, `/sync/catalogo`, `/cuenta` → **401** (prueba en vivo). `SecurityConfig.java`: todo autenticado salvo `/auth/**`, health, docs y `/error`. | — |
| 02 | Secretos fuera del cliente | OK | — | La app solo lleva `API_URL` (pública por diseño). Sin llaves en `mobile/lib`. | — |
| 03 | Aislamiento entre usuarios | OK | Bajo | `usuarioId` sale del token, nunca del cuerpo. Prueba `unNegocioNoPuedeModificarElProductoDeOtro`. Nota: `MovimientoRepository.idsExistentes` busca ids sin filtrar por usuario (un UUID ajeno se marcaría "duplicado"); con UUID v4 es improbable. | Filtrar por usuario en `idsExistentes`. |
| 04 | HTTPS obligatorio | OK | — | `http://` → **308** a `https://`. Certificado Let's Encrypt (Caddy). HSTS `max-age=31536000; includeSubDomains`. | — |
| 05 | Contraseñas protegidas | Parcial | Bajo | `BCryptPasswordEncoder(12)` en `SecurityConfig.java:22`. La guía (OWASP) recomienda Argon2id; bcrypt es alternativa aceptable. | Argon2id con `DelegatingPasswordEncoder` (migra al iniciar sesión, sin romper cuentas). |
| 06 | Validación en el servidor | OK | — | DTO con `@Valid` (`@Positive`, `@Size`, `@Pattern`, rangos de delta). En vivo: datos inválidos → **400** con mensaje. | — |
| 07 | Protección XSS | No aplica | — | API JSON y app nativa: no se interpreta HTML. | — |
| 08 | Registros y alertas | FALLA | Medio | No hay registro de eventos de seguridad (ingresos fallidos, bloqueos, borrado de cuenta) ni alertas. Los logs no contienen claves (revisado). | Registro de auditoría estructurado (sin datos personales) y alertas de caída/errores. |
| 09 | Permisos de administrador | No aplica | — | No existen endpoints de administración. Actuator solo expone `health`; `/actuator/env` y `/heapdump` → **401**. | — |
| 10 | Consultas seguras | OK | — | JPA/JPQL con parámetros (`@Param`); sin SQL concatenado. En la app, `sqflite` con `whereArgs`. | — |
| 11 | Variables de entorno | OK | — | `.env` ignorado por git; `.env.example` solo con marcadores; en el VPS `.env` con permisos 600 y claves aleatorias. | — |
| 12 | Límite de solicitudes | Parcial | Bajo | Ráfaga de 260 → **197 respuestas 429** (funciona). Ventana fija de 1 minuto: se puede duplicar el límite en el cambio de minuto. Bloqueo por cuenta tras 5 claves erradas (15 min); permite bloquear la cuenta de otro si se conoce su celular. Registro sin límite propio. | Ventana deslizante; límite específico para `login` y `registro`; bloqueo progresivo. |
| 13 | CORS controlado | OK | — | Preflight desde `https://atacante.example` → **403**, sin `Access-Control-Allow-Origin`. | — |
| 14 | Cabeceras de seguridad | OK | Bajo | `HSTS`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Cache-Control: no-store`. Falta `Referrer-Policy` (menor en una API). | `Referrer-Policy: no-referrer` y `Content-Security-Policy: default-src 'none'`. |
| 15 | Cookies de sesión | No aplica | — | Sesión con token en cabecera `Authorization`, sin cookies. | — |
| 16 | Protección CSRF | No aplica | — | Sin cookies ni sesión de navegador; CSRF deshabilitado a propósito (`SecurityConfig.java`). | — |
| 17 | Recuperación segura | No aplica | — | Recuperación por SMS retirada; se atiende por soporte. | Al retomarla: códigos de un solo uso con vencimiento (ya probado en `52b23af`). |
| 18 | Carga de archivos | No aplica | — | La app no sube archivos. | — |
| 19 | Precios y webhooks | OK | — | Sin pasarela de pagos; los totales se calculan en el teléfono del dueño y el servidor solo los guarda (no hay precio que un tercero pueda manipular). | — |
| 20 | Errores de producción | Parcial | Bajo | Error forzado → `{"detail":"Failed to read request"}`, sin traza. Pero `/v3/api-docs` → **200** y Swagger público en producción (expone el mapa de la API). | Desactivar Swagger en producción o protegerlo. |
| 21 | Paquetes vulnerables | FALLA | **Alto** | `spring-boot-starter-parent 3.3.5` (octubre 2024): la línea 3.3 ya no recibe parches gratuitos; Tomcat, Spring Security y Jackson tienen correcciones posteriores. `springdoc 2.6.0` antiguo. App: 25 paquetes con versiones nuevas. VPS: 19 paquetes por actualizar. | Spring Boot vigente y springdoc compatible; `flutter pub upgrade` controlado; `apt upgrade`; escáner de dependencias en CI. |
| 22 | Paquetes sin uso | NO VERIFICADO | Bajo | No se corrió analizador. | `mvn dependency:analyze` y revisión de `pubspec`. |
| 23 | Archivos privados expuestos | OK | — | `/.env`, `/.git/config`, `/backup.sql` → **401**; la base no publica puertos; respaldos fuera de rutas web. | — |
| 24 | Historial de git | OK | — | Búsqueda en todo el historial de tokens Twilio, llaves AWS/Stripe y llaves privadas: **0** coincidencias; nunca se versionó un `.env`. | Gitleaks en CI. |
| 25 | Rotación de credenciales | FALLA | Medio | El *Auth Token* de Twilio se pegó en un chat (ya no se usa en el proyecto). El JWT de ejemplo se usó en local y ya se cambió; el del VPS es aleatorio. | **Dueño:** regenerar el token en la consola de Twilio. |
| 26 | Revisión OWASP adicional | Parcial | Medio | (a) Token de 60 min sin renovación: al vencer, la app deja de sincronizar hasta volver a entrar, y no hay revocación al cerrar sesión ni al borrar la cuenta. (b) Respaldos en el mismo VPS, sin cifrar y con permisos 644. (c) Un solo servidor compartido con otro proyecto. (d) PIN de 4 dígitos con SHA-256: candado de comodidad guardado en el almacén seguro del sistema. (e) SSH entra como `root` (solo con llave) y `X11Forwarding yes`. | Token de acceso corto + renovación rotativa y revocable; respaldos cifrados y fuera del VPS con prueba de restauración; usuario SSH sin root y `X11Forwarding no`. |
| 27 | Pruebas e informe | OK | — | Este documento; 15 pruebas de API y 41 de app; pruebas en vivo registradas arriba. | Repetir tras cada corrección. |

Bien resuelto y verificado en la infraestructura: SSH solo con llave (`passwordauthentication no`, `maxauthtries 3`), firewall `ufw` activo (solo 22, 80 y 443), `fail2ban` y actualizaciones automáticas activos, contenedor de la API sin root (`uid=100(caporal)`), base de datos sin puertos públicos, base local del teléfono cifrada con SQLCipher y llave en Keychain/Keystore.

## 3. Relación con ISO/IEC 27001:2022 y SOC 2

| Tema | ISO 27001:2022 (Anexo A) | SOC 2 (TSC) | Estado en Caporal |
|---|---|---|---|
| Control de acceso y autenticación | A.5.15, A.5.17, A.8.2, A.8.3, A.8.5 | CC6.1, CC6.2, CC6.3 | Bien: autenticación en el servidor, aislamiento por negocio, bloqueo por intentos. Falta: renovación/revocación de sesión, Argon2id. |
| Criptografía | A.8.24 | CC6.1, CC6.7 | Bien: TLS, HSTS, SQLCipher, bcrypt. Falta: cifrar respaldos. |
| Seguridad de red y perímetro | A.8.20, A.8.21, A.8.22 | CC6.6 | Bien: ufw, solo 80/443/22, base sin exponer, CORS cerrado. |
| Vulnerabilidades y configuración | A.8.8, A.8.9 | CC7.1 | **Falla:** framework sin soporte, paquetes pendientes; falta escáner automático. |
| Desarrollo seguro y pruebas | A.8.25, A.8.26, A.8.28, A.8.29 | CC8.1 | Bien: validación, consultas parametrizadas, pruebas automatizadas. Falta: CI activa (bloqueada por pago en GitHub) y escaneo de secretos. |
| Gestión de cambios | A.8.32 | CC8.1 | Parcial: todo pasa por git, pero se sube directo a `main` sin revisión ni CI. |
| Registro y monitoreo | A.8.15, A.8.16 | CC7.2, CC7.3 | **Falla:** sin registro de auditoría ni alertas. |
| Respaldo y continuidad | A.8.13, A.5.30 | A1.2, A1.3 | Parcial: copia diaria verificada, pero en el mismo servidor, sin cifrar y sin prueba de restauración periódica. |
| Gestión de incidentes | A.5.24 – A.5.28 | CC7.4, CC7.5 | Falta: procedimiento escrito y contactos. |
| Privacidad y datos personales (Ley 1581) | A.5.34, A.8.10, A.8.11 | C1.1, C1.2, P-series | Bien: autorización en el registro, minimización, número de clientes solo en el teléfono con consentimiento, borrado de cuenta y exportación. |
| Integridad del procesamiento | A.8.28 | PI1.x | Bien: movimientos inmutables, sincronización idempotente probada, transacciones atómicas en el teléfono. |
| Proveedores y nube | A.5.19 – A.5.23 | CC9.2 | Falta: inventario de proveedores (VPS, sslip.io/Let's Encrypt, Apple, GitHub) y su evaluación. |
| Gobierno (cláusulas 4–10 de ISO; CC1–CC5 de SOC 2) | Contexto, política, riesgos, SoA, auditoría interna | CC1 – CC5 | Falta: procesos de la organización (ver §4). |

## 4. Plan de hardening propuesto (pendiente de aprobación)

Cambios pequeños, separados y cada uno con su prueba.

**Prioridad alta**
1. Actualizar Spring Boot a la línea vigente y springdoc compatible; correr todas las pruebas de API. *(A.8.8 · CC7.1)*
2. Sesión con token de acceso corto y token de renovación rotativo, guardado en el almacén seguro del teléfono y revocable al cerrar sesión o borrar la cuenta; la app renueva sola, así la sincronización no se detiene. *(A.8.5 · CC6.1)*
3. Respaldos cifrados, permisos 600 y copia fuera del VPS; prueba de restauración documentada. *(A.8.13 · A1.2, A1.3)*
4. **Dueño:** rotar el token de Twilio en su consola. *(A.5.17)*

**Prioridad media**
5. Registro de auditoría de eventos de seguridad (ingreso fallido, bloqueo, borrado de cuenta) sin datos personales, y alerta externa de caída sobre `/actuator/health`. *(A.8.15, A.8.16 · CC7.2)*
6. Límite de solicitudes con ventana deslizante y específico para login y registro. *(A.8.20 · CC6.6)*
7. Swagger desactivado en producción; cabeceras `Referrer-Policy` y CSP. *(A.8.9)*
8. Argon2id con migración transparente desde bcrypt. *(A.8.24)*
9. VPS: `apt upgrade`, `X11Forwarding no`, usuario de despliegue sin root. *(A.8.9 · CC6.1)*
10. CI con escáner de secretos (Gitleaks) y de dependencias; ramas protegidas. Requiere resolver el bloqueo de pago de GitHub. *(A.8.25, A.8.32 · CC8.1)*

**Gobierno (documentos para ISO 27001 / SOC 2)**
11. Política de seguridad, matriz de riesgos, declaración de aplicabilidad (SoA), procedimiento de incidentes, inventario de activos y proveedores, y política de respaldos y continuidad. Se pueden redactar borradores; su aprobación y operación corresponden a la organización.

## 5. Límites de esta revisión

- No se ejecutó escáner de vulnerabilidades de dependencias (OWASP Dependency-Check, Trivy): **NO VERIFICADO** el listado exacto de CVE.
- No se probó una versión publicada en tiendas (no existe todavía).
- No se hicieron pruebas de carga; la ráfaga de 260 solicitudes fue sobre el propio sistema.

---

## 6. Re-auditoría tras el endurecimiento (17/11/2026, 3:00 p. m.)

Aplicado el plan del §4 (aprobado por el responsable). Cada fila se volvió a probar en vivo contra `https://caporal.2.25.187.25.sslip.io` o con pruebas automáticas.

| # | Control | Antes | Ahora | Evidencia nueva |
|---|---|---|---|---|
| 03 | Aislamiento | OK (nota) | **OK** | `idsExistentes` filtra por negocio (`MovimientoRepository`). |
| 05 | Contraseñas | Parcial | **OK** | Argon2id (19 MiB, t=2, p=1) con migración desde bcrypt al ingresar. Pruebas `lasClavesNuevasSeGuardanConArgon2id` y `unaClaveAntiguaEnBcryptSigueEntrandoYSeMigraAArgon2id`. |
| 08 | Registros y alertas | FALLA | **OK** (alertas: falta destino) | Logger `seguridad` en vivo: `evento=registro`, `ingreso`, `reutilizacion_token_renovacion`, `cuenta_eliminada`, `limite_excedido` (IP como huella). `vigilar.sh` cada 5 min con reinicio; destino de alertas `ALERTA_WEBHOOK` por definir. |
| 12 | Límites | Parcial | **OK** | Cubetas continuas por ruta. En vivo: 40 ingresos simultáneos → 29 respuestas 429 mientras `/actuator/health` seguía en 200. Prueba `RateLimitFilterTest`. |
| 14 | Cabeceras | OK (falta Referrer) | **OK** | En vivo: `content-security-policy: default-src 'none'; frame-ancestors 'none'`, `referrer-policy: no-referrer`, HSTS, nosniff. |
| 20 | Errores / documentación | Parcial | **OK** | `/v3/api-docs` y `/swagger-ui.html` → **404** en producción. |
| 21 | Paquetes vulnerables | FALLA | **OK** (CI pendiente) | Spring Boot **4.1.2** (Spring Security 7.1.2, Tomcat 11.0.27), springdoc 3.2.0, jjwt 0.13.0, Bouncy Castle 1.87. VPS: paquetes del sistema actualizados salvo Docker (ventana pendiente). Dependabot + Trivy en CI. |
| 24 | Historial de git | OK | **OK** | Gitleaks agregado a la CI. |
| 25 | Rotación | FALLA | **Pendiente del dueño** | Regenerar el token de Twilio en su consola. |
| 26a | Sesión | Parcial | **OK** | Acceso 15 min + renovación de un solo uso. En vivo: renovar → 200; reusar el mismo token → 401 y revocación de todas las sesiones. Cerrar sesión y borrar la cuenta revocan. 9 pruebas en `SesionesYClavesTest`. La app renueva sola y pide entrar de nuevo si no puede. |
| 26b | Respaldos | Parcial | **OK** | Cifrados con `age` (`age-encryption.org/v1`), permisos 600, llave privada fuera del servidor, copia en el computador del responsable, **prueba de restauración superada** (6 tablas, 1 usuario, 3 movimientos). Respaldo en claro anterior eliminado. |
| 26e | SSH / privilegios | Parcial | **Parcial** | `X11Forwarding no` (verificado con `sshd -T`); Caporal corre y se despliega con el usuario `despliegue`. Root sigue entrando con llave porque el servidor lo comparte otro proyecto (riesgo aceptado, R7). |

### Pendientes conocidos
1. **Dueño:** rotar el token de Twilio.
2. **Dueño:** resolver el bloqueo de pago de GitHub para que corran CI, Gitleaks y Trivy; después proteger la rama `main`.
3. **Dueño:** elegir destino de alertas (`ALERTA_WEBHOOK`, por ejemplo un tema privado de ntfy.sh).
4. **Ventana de mantenimiento:** actualizar Docker y reiniciar el VPS (el sistema lo pide); afecta también al otro proyecto del servidor.
5. Copia de la llave privada de respaldos en el gestor de contraseñas.
6. Dominio propio en lugar de `sslip.io`.

### Documentos de gobierno (borradores)
`politica-seguridad.md`, `matriz-riesgos.md`, `declaracion-aplicabilidad.md`, `procedimiento-incidentes.md`, `inventario-activos-proveedores.md`, `politica-respaldos-continuidad.md`.

### Evidencia adicional — control 21 (escaneo de dependencias)
Trivy 0.76.2, base `ghcr.io/aquasecurity/trivy-db:2`, severidad HIGH y CRITICAL con corrección disponible, 17/11/2026:

| Objetivo | Tipo | Vulnerabilidades |
|---|---|---|
| `backend/pom.xml` | Maven | **0** |
| `mobile/pubspec.lock` | pub | **0** |
| `mobile/ios/Podfile.lock` | CocoaPods | **0** |

Comando: `trivy fs --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed backend` (y `mobile`). El mismo escaneo corre en la CI cuando se active.
