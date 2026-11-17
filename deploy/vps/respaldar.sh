#!/usr/bin/env bash
# Copia diaria de la base de Caporal, cifrada con age (ISO 27001 A.8.13 · SOC 2 A1.2).
# El servidor solo tiene la llave PÚBLICA: puede cifrar pero no leer los respaldos.
# La llave privada vive fuera del servidor (ver README, "Respaldos").
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env; set +a
: "${RESPALDO_CLAVE_PUBLICA:?Falta RESPALDO_CLAVE_PUBLICA en .env}"

destino=/var/backups/caporal
umask 077
mkdir -p "$destino"
plano=$(mktemp)
trap 'shred -u "$plano" 2>/dev/null || rm -f "$plano"' EXIT

docker exec caporal-db-1 sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' > "$plano"
# Una copia que no se puede restaurar no sirve: se verifica antes de cifrar.
[ "$(grep -c 'CREATE TABLE' "$plano")" -gt 0 ] || { echo "Respaldo vacío" >&2; exit 1; }

archivo="$destino/caporal-$(date +%F).sql.gz.age"
gzip -c "$plano" | age -r "$RESPALDO_CLAVE_PUBLICA" > "$archivo"
chmod 600 "$archivo"
find "$destino" -name 'caporal-*.sql.gz.age' -mtime +14 -delete
echo "$(date -Is) respaldo cifrado: $archivo ($(stat -c %s "$archivo") bytes)"
