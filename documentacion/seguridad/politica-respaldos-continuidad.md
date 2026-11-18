# Política de respaldos y continuidad

> **Borrador.** Fecha: 17/11/2026.

| Tema | Regla | Cómo se cumple |
|---|---|---|
| Frecuencia | Diario | cron 3:15 UTC (`respaldar.sh`) |
| Retención | 14 días en el servidor; semanal fuera del servidor | `find -mtime +14`; `bajar-respaldos.sh` |
| Cifrado | Siempre, llave privada fuera del servidor | `age`; llave en el computador del responsable y en gestor de contraseñas |
| Verificación | Cada respaldo se valida antes de cifrar | `respaldar.sh` revisa `CREATE TABLE` |
| Prueba de restauración | Mensual, registrada | `probar-restauracion.sh` (primera prueba: 17/11/2026, 6 tablas, OK) |
| Objetivos | RPO 24 h · RTO 4 h | Restauración documentada en `deploy/vps/README.md` |
| Continuidad del negocio | La app funciona sin servidor | Todo se guarda primero en el teléfono y se sincroniza al volver la conexión |
