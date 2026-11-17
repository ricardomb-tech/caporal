#!/usr/bin/env bash
# Se ejecuta en el computador del responsable: copia fuera del VPS de los respaldos (siguen cifrados).
set -euo pipefail
servidor="${1:-despliegue@2.25.187.25}"
destino="$HOME/Respaldos/caporal"
mkdir -p "$destino" && chmod 700 "$destino"
rsync -a "$servidor:/var/backups/caporal/" "$destino/"
chmod 600 "$destino"/*.age
echo "Respaldos cifrados en $destino:"; ls -lh "$destino" | tail -5
