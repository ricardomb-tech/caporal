# Controles de seguridad

Estado de los diez controles que piden las bases de la convocatoria.

| Control | Implementación | Estado |
|---|---|---|
| Comunicaciones seguras | HTTPS con TLS 1.2+ en el proxy de despliegue; la app solo debe apuntar a `https://` en producción | Pendiente de despliegue |
| Protección de la información | Base local cifrada con SQLCipher; llave en Keystore / Keychain; contraseñas con BCrypt (sal por contraseña, costo 12) | Hecho |
| Autenticación y sesiones | Clave mínima de 8 caracteres, bloqueo temporal tras intentos fallidos, JWT de 60 minutos, API sin sesión en servidor | Hecho; falta renovación de token |
| Desarrollo seguro | Consultas parametrizadas (JPA y `?` en SQLite); revisión contra OWASP Mobile y API Top 10 | En curso |
| Validación de entradas | Bean Validation en todos los cuerpos de la API; validación de formularios en la app | Hecho en la API |
| Gestión de secretos | Variables de entorno; `.env` fuera del repositorio; `.env.example` sin valores reales | Hecho |
| Registro y trazabilidad | Logs sin claves, tokens ni datos personales | En curso |
| Componentes de terceros | Solo licencias permisivas; lista generada desde `pom.xml` y `pubspec.yaml` | En curso |
| Seguridad de APIs | Cada consulta filtra por el negocio del token; límite de solicitudes por IP | Hecho |
| Continuidad | Copia diaria de PostgreSQL y restauración probada | Pendiente de despliegue |

## Datos personales (Ley 1581 de 2012)

- De los clientes del negocio solo se guarda el nombre.
- El registro exige aceptar la política de tratamiento y guarda la fecha de aceptación.
- La MiPyme es Responsable; la Gobernación, Encargada.
- La política se puede leer dentro de la app (Ajustes · Privacidad y datos); el registro explica en cuatro puntos qué se guarda, para qué, quién responde y qué derechos hay.
- Acceso: la app copia todos los datos del negocio en JSON.
- Rectificación: nombre y correo se corrigen desde Mis datos personales.
- Supresión: `DELETE /api/v1/cuenta` borra cuenta y movimientos en el servidor y luego la app borra el teléfono (ADR-04). Probado en `SyncFlujoTest`.
- Cifras anónimas para estudios: casilla opcional, apagada por defecto. Hoy solo guarda la decisión; no se envía nada hasta definir qué cifras y con qué agregación.
- PIN de 4 números: candado de comodidad guardado como hash SHA-256 con sal en el almacén seguro; 5 fallos bloquean 30 segundos. No sustituye la clave de la cuenta.
