# Inventario de activos y proveedores

> **Borrador.** Fecha: 17/11/2026. Revisión trimestral.

## Activos
| Activo | Ubicación | Clasificación | Dueño |
|---|---|---|---|
| Base de datos de producción (cuentas, movimientos, inventario) | VPS, volumen `caporal_db` | Confidencial | Responsable de seguridad |
| Respaldos cifrados | VPS `/var/backups/caporal` y computador del responsable | Confidencial | Responsable de seguridad |
| Llave privada de respaldos | Computador del responsable y gestor de contraseñas | Secreta | Responsable de seguridad |
| Secretos de la API (`.env`) | VPS, permisos 600 | Secreta | Responsable de seguridad |
| Llave de firma de Android (`caporal-subida.jks`) y su clave | Computador del responsable, `~/.caporal/` (permisos 600); copia pendiente en el gestor de contraseñas | Secreta | Responsable de seguridad |
| Símbolos de la app ofuscada (para leer errores) | `~/.caporal/simbolos/<versión>` | Interna | Equipo |
| Código fuente | GitHub `ricardomb-tech/caporal` | Interna | Equipo |
| Base local de cada teléfono | Dispositivo del negocio (SQLCipher) | Confidencial | Cada negocio |

## Proveedores
| Proveedor | Uso | Datos que trata | Evaluación |
|---|---|---|---|
| Proveedor del VPS | Servidor de producción de pruebas | Todos los de la API | Pendiente: contrato, ubicación y certificaciones |
| Let's Encrypt / DNS provisional | Certificado HTTPS / nombre DNS | Ninguno | Bajo riesgo; reemplazar el nombre provisional por un dominio propio |
| GitHub | Código y CI | Código (sin datos personales) | Aceptado |
| Apple (TestFlight/App Store) y Google Play | Distribución de la app | Ninguno de los negocios | Aceptado |
| WhatsApp (del dueño del negocio) | Envío de recordatorios | Mensaje que el dueño decide enviar | El dueño lo opera desde su propio teléfono |
