# Declaración de aplicabilidad (SoA) — selección inicial

> **Borrador.** Una SoA formal de ISO/IEC 27001:2022 debe pronunciarse sobre los 93 controles del Anexo A; esta tabla cubre los que hoy tienen evidencia técnica o una decisión explícita. Fecha: 17/11/2026.

| Control | Aplica | Estado | Evidencia / justificación |
|---|---|---|---|
| A.5.1 Políticas | Sí | Borrador | `politica-seguridad.md` |
| A.5.15 Control de acceso | Sí | Implementado | `SecurityConfig.java`, pruebas 401 |
| A.5.17 Información de autenticación | Sí | Implementado | Argon2id, tokens en almacén seguro |
| A.5.24–A.5.28 Incidentes | Sí | Borrador | `procedimiento-incidentes.md` |
| A.5.30 Continuidad TIC | Sí | Parcial | App sin conexión, respaldos; sin servidor redundante |
| A.5.34 Privacidad y datos personales | Sí | Implementado | Autorización en registro, consentimiento del celular del cliente, exportar y borrar |
| A.8.1 Dispositivos de usuario final | Sí | Implementado | SQLCipher, PIN, llave en Keychain/Keystore |
| A.8.2 Accesos privilegiados | Sí | Parcial | Usuario `despliegue`; root solo con llave (servidor compartido) |
| A.8.3 Restricción de acceso a la información | Sí | Implementado | Filtro por negocio; prueba de aislamiento |
| A.8.5 Autenticación segura | Sí | Implementado | Sesión corta + renovación rotativa; bloqueo; límites |
| A.8.8 Vulnerabilidades técnicas | Sí | Implementado (CI pendiente) | Spring Boot 4.1.2, Dependabot, Trivy |
| A.8.9 Gestión de la configuración | Sí | Implementado | Todo en git; `deploy/vps`; Swagger off en producción |
| A.8.12 Prevención de fuga de datos | Sí | Parcial | Logs sin datos personales; Gitleaks |
| A.8.13 Respaldo | Sí | Implementado | Cifrado age, copia externa, prueba de restauración |
| A.8.15 Registro | Sí | Implementado | Logger `seguridad` con eventos |
| A.8.16 Monitoreo | Sí | Implementado (alertas por configurar) | `vigilar.sh` cada 5 min |
| A.8.20 Seguridad de redes | Sí | Implementado | ufw, solo 22/80/443, base sin puertos |
| A.8.24 Criptografía | Sí | Implementado | TLS + HSTS, Argon2id, SQLCipher, age |
| A.8.25 Ciclo de desarrollo seguro | Sí | Parcial | Pruebas automáticas; CI bloqueada por pago de GitHub |
| A.8.28 Codificación segura | Sí | Implementado | Validación, consultas parametrizadas, errores sin trazas |
| A.8.32 Gestión de cambios | Sí | Parcial | Git; falta rama protegida con revisión |
| A.7.x Seguridad física | No | — | Infraestructura en proveedor de nube; se cubre con su certificación |
| A.6.x Personas (selección, formación) | Sí | Pendiente | Definir al formalizar el equipo |
