#!/usr/bin/env bash
# Despliega o actualiza Caporal en el VPS: trae el código, reconstruye la API y espera a que esté sana.
set -euo pipefail
cd "$(dirname "$0")"
git -C ../.. pull --ff-only
docker compose up -d --build
for _ in $(seq 1 40); do
  estado=$(docker inspect -f '{{.State.Health.Status}}' caporal-api-1 2>/dev/null || echo "iniciando")
  [ "$estado" = "healthy" ] && { echo "Caporal API: sana"; exit 0; }
  sleep 5
done
echo "La API no quedó sana; revise: docker compose logs api" >&2
exit 1
