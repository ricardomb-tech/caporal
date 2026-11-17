# Despliegue en el VPS

La API y PostgreSQL corren en un proyecto Docker propio (`caporal`) bajo el usuario `despliegue` (sin root),
en `/opt/caporal`. No abren puertos: el Caddy que ya atiende 80/443 en el VPS les llega por la red `proxy`
y pone el HTTPS (Let's Encrypt). Documentación de la API desactivada en producción y logs acotados.

## Primera vez (como root)

```bash
useradd -m -s /bin/bash despliegue && usermod -aG docker despliegue
install -d -m 700 -o despliegue -g despliegue ~despliegue/.ssh   # y agregue la llave pública en authorized_keys
git clone https://github.com/ricardomb-tech/caporal.git /opt/caporal && chown -R despliegue: /opt/caporal
install -d -m 700 -o despliegue -g despliegue /var/backups/caporal /var/lib/caporal
```

Luego, como `despliegue`:

```bash
cd /opt/caporal/deploy/vps
cp ../../.env.example .env && chmod 600 .env   # y complete TODAS las claves (ver abajo)
./desplegar.sh
crontab - <<'CRON'
15 3 * * * /opt/caporal/deploy/vps/respaldar.sh >> /var/lib/caporal/respaldo.log 2>&1
*/5 * * * * /opt/caporal/deploy/vps/vigilar.sh >> /var/lib/caporal/vigilancia.log 2>&1
CRON
```

Y agregue `caddy-caporal.caddy` al Caddyfile del proxy y recárguelo (`caddy validate` antes de `caddy reload`).

Claves del `.env`: `POSTGRES_PASSWORD` y `JWT_SECRET` con `openssl rand -base64 48`; `RESPALDO_CLAVE_PUBLICA`
(línea "public key" de `age-keygen`), `DOMINIO_PUBLICO` y, si quiere alertas, `ALERTA_WEBHOOK`.

## Actualizar

```bash
ssh despliegue@2.25.187.25 /opt/caporal/deploy/vps/desplegar.sh
```

## Respaldos

- Diarios a las 3:15 UTC, cifrados con `age` en `/var/backups/caporal` (14 días, permisos 600).
- La **llave privada** está fuera del servidor (en el computador del responsable, `~/.caporal/llave-respaldos.txt`)
  y debe guardarse también en un gestor de contraseñas. Sin ella los respaldos no se pueden abrir.
- Copia fuera del VPS: `deploy/vps/bajar-respaldos.sh` (en el computador del responsable, semanal).
- Prueba de restauración (mensual): `deploy/vps/probar-restauracion.sh`. Carga el último respaldo en una base
  temporal, cuenta tablas y registros, y la borra.

Restaurar de verdad (solo ante un incidente):

```bash
age -d -i ~/.caporal/llave-respaldos.txt caporal-AAAA-MM-DD.sql.gz.age | gunzip \
  | ssh despliegue@2.25.187.25 'docker exec -i caporal-db-1 psql -U caporal caporal'
```

## Vigilancia

`vigilar.sh` revisa cada 5 minutos la salud de la API, el HTTPS público y el disco; reinicia la API si no
responde y, con `ALERTA_WEBHOOK`, avisa cuando cambia el estado. Registro: `/var/lib/caporal/vigilancia.log`.
Eventos de seguridad de la API: `docker compose logs api | grep 'evento='`.
