# Procedimiento de incidentes de seguridad

> **Borrador.** Fecha: 17/11/2026. Responsable: Ricardo Daniel Martínez Banda.

## 1. Detectar
Fuentes: alerta de `vigilar.sh`, eventos `evento=reutilizacion_token_renovacion` / `cuenta_bloqueada` / `limite_excedido` en `docker compose logs api`, aviso de un usuario o de un tercero.

## 2. Clasificar (primeros 30 minutos)
| Nivel | Ejemplo | Tiempo de respuesta |
|---|---|---|
| Crítico | Acceso no autorizado a datos, fuga de secretos | Inmediato |
| Alto | Servicio caído más de 1 hora, reuso de tokens repetido | 4 horas |
| Medio/bajo | Picos de 429, intentos fallidos | 1 día hábil |

## 3. Contener
- Secreto expuesto: rotarlo (JWT: cambiar `JWT_SECRET` y reiniciar la API invalida todos los accesos).
- Cuenta comprometida: revocar sus sesiones (`update sesion set revocado_en=now() where usuario_id=…`).
- Servidor comprometido: cortar acceso público (quitar el bloque de Caddy) y conservar evidencia (logs, imagen del disco).

## 4. Erradicar y recuperar
Corregir la causa, desplegar con `desplegar.sh`, restaurar desde respaldo si hace falta (ver `deploy/vps/README.md`).

## 5. Notificar
- Usuarios afectados: claro y sin tecnicismos.
- Superintendencia de Industria y Comercio: incidentes con datos personales, en los plazos del Registro Nacional de Bases de Datos.
- Gobernación de Casanare (Encargada), según el acuerdo.

## 6. Aprender
Informe en `documentacion/seguridad/incidentes/AAAA-MM-DD.md`: línea de tiempo, causa, acciones y control nuevo. Actualizar la matriz de riesgos.
