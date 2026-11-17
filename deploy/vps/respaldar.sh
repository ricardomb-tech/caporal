#!/usr/bin/env bash
# Copia diaria de la base de Caporal (se programa con cron). Guarda 14 días.
set -euo pipefail
destino=/root/respaldos/caporal
mkdir -p "$destino"
archivo="$destino/caporal-$(date +%F).sql.gz"
docker exec caporal-db-1 sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' | gzip > "$archivo"
# Una copia que no se puede leer no sirve: se verifica que tenga contenido.
[ "$(gzip -dc "$archivo" | grep -c 'CREATE TABLE')" -gt 0 ] || { echo "Respaldo vacío: $archivo" >&2; exit 1; }
find "$destino" -name 'caporal-*.sql.gz' -mtime +14 -delete
echo "Respaldo listo: $archivo"
