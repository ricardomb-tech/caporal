#!/usr/bin/env bash
# Vigilancia cada 5 minutos (ISO 27001 A.8.16 · SOC 2 CC7.2): salud de la API, certificado/proxy y disco.
# Si la API no responde, la reinicia. Si ALERTA_WEBHOOK está en .env, avisa al cambiar de estado
# (por ejemplo un tema de ntfy.sh o un webhook de Slack/Discord).
set -uo pipefail
cd "$(dirname "$0")"
set -a; . ./.env; set +a
estado_archivo=/var/lib/caporal/vigilancia.estado
mkdir -p "$(dirname "$estado_archivo")"
anterior=$(cat "$estado_archivo" 2>/dev/null || echo "ok")

problemas=()
salud=$(docker inspect -f '{{.State.Health.Status}}' caporal-api-1 2>/dev/null || echo "ausente")
[ "$salud" = "healthy" ] || problemas+=("api:$salud")
curl -fsS --max-time 15 "https://${DOMINIO_PUBLICO}/actuator/health" | grep -q UP || problemas+=("https_publico")
uso=$(df --output=pcent / | tail -1 | tr -dc '0-9')
[ "$uso" -lt 85 ] || problemas+=("disco:${uso}%")

if [ ${#problemas[@]} -eq 0 ]; then
  actual="ok"
else
  actual="falla: ${problemas[*]}"
  if [ "$salud" != "healthy" ] && [ "$salud" != "starting" ]; then
    docker compose restart api >/dev/null 2>&1 && problemas+=("api_reiniciada")
  fi
fi

if [ "$actual" != "$anterior" ]; then
  echo "$(date -Is) Caporal: $actual ${problemas[*]:-}"
  if [ -n "${ALERTA_WEBHOOK:-}" ]; then
    curl -fsS --max-time 10 -H "Content-Type: text/plain" -d "Caporal: $actual" "$ALERTA_WEBHOOK" >/dev/null || true
  fi
fi
echo "$actual" > "$estado_archivo"
