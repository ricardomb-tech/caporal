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
- Pendiente: texto de la política dentro de la app y opción de exportar y eliminar los datos.
