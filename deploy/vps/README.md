# Despliegue en el VPS

La API y PostgreSQL corren en un proyecto Docker propio (`caporal`). No abren puertos: el Caddy que ya
atiende 80/443 en el VPS les llega por la red `proxy` y pone el HTTPS (Let's Encrypt).

## Primera vez

```bash
git clone https://github.com/ricardomb-tech/caporal.git /root/caporal
cd /root/caporal/deploy/vps
cp ../../.env.example .env          # y cambie TODAS las claves (ver abajo)
./desplegar.sh
cat caddy-caporal.caddy >> <Caddyfile del proxy>   # agregar al final, sin reemplazar el archivo
docker exec <contenedor-caddy> caddy reload --config /etc/caddy/Caddyfile
crontab -l | { cat; echo "15 3 * * * /root/caporal/deploy/vps/respaldar.sh >> /var/log/caporal-respaldo.log 2>&1"; } | crontab -
```

Claves: `POSTGRES_PASSWORD` y `JWT_SECRET` con `openssl rand -base64 48`.
`RED_PROXY` es la red del Caddy existente (por defecto `domiz-pruebas_default`).

## Actualizar

```bash
/root/caporal/deploy/vps/desplegar.sh
```

## Comprobar

```bash
curl https://caporal.2.25.187.25.sslip.io/actuator/health
```

## Restaurar un respaldo

```bash
gzip -dc /root/respaldos/caporal/caporal-AAAA-MM-DD.sql.gz | docker exec -i caporal-db-1 psql -U caporal caporal
```
