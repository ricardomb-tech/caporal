#!/usr/bin/env bash
# Prueba de restauración (ISO 27001 A.8.13 · SOC 2 A1.3). Se ejecuta en el computador que tiene la llave privada:
# descifra el último respaldo, lo carga en una base TEMPORAL en el VPS (nunca en la real), cuenta tablas
# y registros, y borra la base temporal. El contenido viaja solo por SSH y no queda en disco.
set -euo pipefail
llave="${LLAVE_RESPALDOS:-$HOME/.caporal/llave-respaldos.txt}"
servidor="${1:-${CAPORAL_SERVIDOR:?Indique el servidor: $0 usuario@servidor, o defina CAPORAL_SERVIDOR}}"
archivo=$(ls -t "$HOME/Respaldos/caporal"/caporal-*.sql.gz.age | head -1)
echo "Probando: $(basename "$archivo")"
age -d -i "$llave" "$archivo" | gunzip | ssh "$servidor" '
  set -e
  c=caporal-prueba-restauracion
  docker rm -f $c >/dev/null 2>&1 || true
  docker run -d --name $c -e POSTGRES_USER=caporal -e POSTGRES_DB=caporal -e POSTGRES_PASSWORD=prueba postgres:16-alpine >/dev/null
  trap "docker rm -f $c >/dev/null" EXIT
  for i in $(seq 1 30); do docker exec $c pg_isready -U caporal -d caporal >/dev/null 2>&1 && break; sleep 1; done
  sleep 2
  docker exec -i $c psql -q -U caporal -d caporal -v ON_ERROR_STOP=1 >/dev/null
  echo "tablas: $(docker exec $c psql -tA -U caporal -d caporal -c "select count(*) from information_schema.tables where table_schema='"'"'public'"'"'")"
  echo "usuarios: $(docker exec $c psql -tA -U caporal -d caporal -c "select count(*) from usuario")"
  echo "movimientos: $(docker exec $c psql -tA -U caporal -d caporal -c "select count(*) from movimiento")"
'
echo "Restauración correcta: $(date "+%Y-%m-%d %H:%M:%S %z")"
