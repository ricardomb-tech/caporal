# Controles de seguridad

Estado de los diez controles que piden las bases de la convocatoria.

| Control | Implementación | Estado |
|---|---|---|
| Comunicaciones seguras | HTTPS con TLS 1.2 y 1.3 y HSTS (Caddy); Android bloquea el tráfico sin cifrar; la app se compila con `API_URL` en `https://` | Hecho |
| Protección de la información | Base local cifrada con SQLCipher; llave en Keystore / Keychain; claves con Argon2id; respaldos del servidor cifrados con `age`; Android no copia los datos de la app a la nube de Google | Hecho |
| Autenticación y sesiones | Clave mínima de 8 caracteres, bloqueo por intentos, acceso de 15 min con renovación de un solo uso (reusarla revoca todo), PIN y huella en el teléfono | Hecho |
| Desarrollo seguro | Consultas parametrizadas; revisión OWASP Mobile y API Top 10 ([auditoría](auditoria-2026-11-17.md)); APK ofuscada y firmada con llave propia | Hecho; falta CI activa |
| Validación de entradas | Bean Validation en todos los cuerpos de la API; validación de formularios en la app | Hecho |
| Gestión de secretos | Variables de entorno; `.env` y llaves fuera del repositorio; sin datos del servidor en el código | Hecho |
| Registro y trazabilidad | Eventos de seguridad sin claves, tokens ni datos personales | Hecho; falta destino de alertas |
| Componentes de terceros | Solo licencias permisivas; Trivy sin vulnerabilidades altas ni críticas; Dependabot | Hecho; falta CI activa |
| Seguridad de APIs | Cada consulta filtra por el negocio del token; límites por ruta e IP; cabeceras de seguridad; Swagger apagado en producción | Hecho |
| Continuidad | Respaldo diario cifrado, copia fuera del servidor y restauración probada; la app trabaja sin servidor | Hecho |

## Datos personales (Ley 1581 de 2012)

- De los clientes del negocio se guarda el nombre y, solo con su autorización, el celular, que nunca sale del teléfono. De los proveedores, solo el nombre.
- El registro exige aceptar la política de tratamiento y guarda la fecha de aceptación.
- La MiPyme es Responsable; la Gobernación, Encargada.
- La política se puede leer dentro de la app (Ajustes · Privacidad y datos); el registro explica en cuatro puntos qué se guarda, para qué, quién responde y qué derechos hay.
- Acceso: la app copia todos los datos del negocio en JSON.
- Rectificación: nombre y correo se corrigen desde Mis datos personales.
- Supresión: `DELETE /api/v1/cuenta` borra cuenta y movimientos en el servidor y luego la app borra el teléfono (ADR-04). Probado en `SyncFlujoTest`.
- Cifras anónimas para estudios: casilla opcional, apagada por defecto. Hoy solo guarda la decisión; no se envía nada hasta definir qué cifras y con qué agregación.
- PIN de 4 números: candado de comodidad guardado como hash SHA-256 con sal en el almacén seguro; 5 fallos bloquean 30 segundos. No sustituye la clave de la cuenta.
