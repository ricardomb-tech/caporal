# Matriz de riesgos — Caporal

> **Borrador.** Escala 1–3 (probabilidad × impacto). Revisión trimestral. Fecha: 17/11/2026.

| # | Riesgo | P | I | Nivel | Tratamiento | Controles (ISO 27001 · SOC 2) | Riesgo residual |
|---|---|---|---|---|---|---|---|
| R1 | Robo de sesión desde un teléfono | 2 | 2 | 4 | Mitigar | Acceso de 15 min, renovación de un solo uso con detección de reuso, almacén seguro del sistema (A.8.5 · CC6.1) | Bajo |
| R2 | Adivinar contraseñas | 2 | 2 | 4 | Mitigar | Argon2id, bloqueo por cuenta, límite por IP en ingreso (A.8.5 · CC6.1) | Bajo |
| R3 | Ver datos de otro negocio | 1 | 3 | 3 | Mitigar | Identidad desde el token, consultas filtradas por negocio, pruebas automáticas (A.8.3 · CC6.1) | Bajo |
| R4 | Vulnerabilidad en dependencias | 2 | 3 | 6 | Mitigar | Spring Boot vigente, Dependabot, Trivy en CI (A.8.8 · CC7.1) | Medio hasta activar la CI |
| R5 | Pérdida de la base de datos | 1 | 3 | 3 | Mitigar | Respaldo diario cifrado, copia fuera del VPS, prueba de restauración (A.8.13 · A1.2/A1.3) | Bajo |
| R6 | Caída del servidor (único VPS) | 2 | 2 | 4 | Aceptar/mitigar | Vigilancia cada 5 min con reinicio; app funciona sin conexión (A.5.30 · A1.2) | Medio (sin redundancia) |
| R7 | Proyecto vecino en el mismo VPS comprometido | 1 | 3 | 3 | Aceptar temporalmente | Red y base separadas; migrar a servidor propio al ganar (A.8.22 · CC6.6) | Medio |
| R8 | Fuga de secretos | 1 | 3 | 3 | Mitigar | `.env` 600, Gitleaks, rotación ante exposición (A.5.17 · CC6.1) | Bajo |
| R9 | Pérdida de la llave privada de respaldos | 1 | 3 | 3 | Mitigar | Copia en gestor de contraseñas del responsable | Bajo |
| R10 | Mal uso del cobro (acoso a deudores) | 1 | 2 | 2 | Mitigar | Horarios, aviso de frecuencia, texto amable fijo (A.5.34 · P) | Bajo |
| R11 | Pérdida o robo del teléfono del negocio | 2 | 2 | 4 | Mitigar | Base cifrada, PIN de la app, borrado remoto de la cuenta (A.8.1 · CC6.1) | Bajo |
