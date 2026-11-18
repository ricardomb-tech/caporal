#!/usr/bin/env bash
# Se ejecuta en el computador del responsable: copia fuera del VPS de los respaldos (siguen cifrados).
set -euo pipefail
servidor="${1:-${CAPORAL_SERVIDOR:?Indique el servidor: $0 usuario@servidor, o defina CAPORAL_SERVIDOR}}"
destino="$HOME/Respaldos/caporal"
mkdir -p "$destino" && chmod 700 "$destino"
rsync -a "$servidor:/var/backups/caporal/" "$destino/"
chmod 600 "$destino"/*.age
echo "Respaldos cifrados en $destino:"; ls -lh "$destino" | tail -5
