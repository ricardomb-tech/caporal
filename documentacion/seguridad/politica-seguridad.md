# Política de seguridad de la información — Caporal

> **Borrador para aprobación** de caporal_tech. Versión 0.1 · 17 de noviembre de 2026. Revisión anual o ante cambios importantes.

## Objetivo
Proteger la confidencialidad, integridad y disponibilidad de las cuentas de los micronegocios que usan Caporal y de los datos personales de sus clientes (Ley 1581 de 2012), con controles proporcionales al tamaño del equipo.

## Alcance
App Caporal (Android/iOS), API y base de datos, servidor de producción, repositorio de código y respaldos.

## Principios
1. **Mínimo dato:** de los clientes de cada negocio solo nombre y, con su autorización, celular (este solo en el teléfono).
2. **Mínimo privilegio:** cada persona y servicio con el acceso justo; producción se opera con el usuario `despliegue`, no con root.
3. **Cifrado:** HTTPS en tránsito; base del teléfono cifrada; respaldos cifrados con llave fuera del servidor.
4. **Todo cambio por git:** sin cambios manuales en producción salvo emergencias documentadas.
5. **Evidencia:** cada control se prueba y la prueba se guarda (ver `auditoria-*.md`).

## Responsabilidades
| Rol | Persona | Responsabilidad |
|---|---|---|
| Responsable de seguridad | Ricardo Daniel Martínez Banda | Esta política, riesgos, accesos, incidentes, revisión trimestral. |
| Desarrollo | Equipo caporal_tech | Desarrollo seguro, pruebas, revisión de dependencias. |
| Encargado del tratamiento | Gobernación de Casanare (al desplegarse en su infraestructura) | Según contrato y Ley 1581. |

## Reglas
- Contraseñas del servicio con Argon2id; sesiones de 15 minutos con renovación revocable.
- Secretos solo en `.env` del servidor (permisos 600) o en gestor de contraseñas; nunca en git ni en chats.
- Dependencias revisadas semanalmente (Dependabot) y en cada cambio (Trivy, Gitleaks).
- Accesos al servidor solo con llave SSH; revisión trimestral de llaves autorizadas.
- Incidentes según `procedimiento-incidentes.md`.

## Cumplimiento
El incumplimiento se trata como incidente. Excepciones: escritas, con fecha de vencimiento y aprobadas por el responsable de seguridad.
