#!/usr/bin/env bash
#
# Recorrido visual de un flavor contra la API real (no la demo) en un
# simulador de iOS. Corre una prueba de `integration_test/` con
# `flutter drive` y responde cada pedido de captura con
# `xcrun simctl io <id> screenshot`.
#
#   tool/recorrido_visual.sh <cliente|piloto> <simulador> [salida]
#
# Requiere la API en `API_BASE_URL` (`config/env.local.json`, local y fuera
# de git) con los datos demo. Las capturas PNG quedan en `salida`
# (por defecto ~/Desktop/agrocom-demo). Ver docs/gestion/recorrido-visual.md.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
F=${1:?flavor}; ID=${2:?simulador}; SALIDA=${3:-$HOME/Desktop/agrocom-demo}
mkdir -p "$SALIDA"
[ -f config/env.local.json ] || { echo "Falta config/env.local.json" >&2; exit 1; }

flutter drive --driver=test_driver/capturas_driver.dart \
  --target="integration_test/recorrido_${F}_test.dart" -d "$ID" --flavor "$F" \
  --dart-define-from-file=config/env.local.json \
  --dart-define=CAPTURAS_DIR="$SALIDA" &
PID=$!
while kill -0 "$PID" 2>/dev/null; do
  for pedido in "$SALIDA"/pedido_*.txt; do
    [ -e "$pedido" ] || continue
    destino=$(cat "$pedido"); rm -f "$pedido"
    xcrun simctl io "$ID" screenshot --type=png "$destino" >/dev/null 2>&1
  done
  sleep 0.2
done
wait "$PID"
