#!/usr/bin/env bash
#
# Captura las pantallas de un flavor en modo demo en un simulador de iOS.
# La prueba `integration_test/<flavor>_capturas_test.dart` deja un pedido por
# pantalla y este script responde con `xcrun simctl io <id> screenshot`.
#
#   tool/capturar_pantallas.sh <cliente|piloto|auxiliar> <simulador> <dispositivo> <claro|oscuro|campo>
#
# Resultado: docs/diseno/capturas/<flavor>/<dispositivo>/<nombre>_<modo>.png
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
F=$1; ID=$2; DEV=$3; MODO=$4
SALIDA="$PWD/docs/diseno/capturas/$F/$DEV"
mkdir -p "$SALIDA"
case "$MODO" in oscuro) xcrun simctl ui "$ID" appearance dark ;; *) xcrun simctl ui "$ID" appearance light ;; esac

flutter drive --driver=test_driver/capturas_driver.dart \
  --target="integration_test/${F}_capturas_test.dart" -d "$ID" --flavor "$F" \
  --dart-define-from-file=config/env.demo.json \
  --dart-define=CAPTURAS_DIR="$SALIDA" --dart-define=CAPTURAS_SUFIJO="$MODO" &
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
