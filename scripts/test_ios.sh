#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Se requiere un Mac con Xcode y un runtime de iOS Simulator instalado." >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "Se requiere Python 3 para seleccionar el simulador iPhone." >&2
  exit 1
fi
# Stop on service failure before parsing; preserve simctl's original diagnostic.
if ! devices_json="$(xcrun simctl list devices available -j)"; then
  echo "No se pudo consultar iOS Simulator. Abre Xcode y Simulator y comprueba que CoreSimulator funciona y que el entorno permite acceder a sus servicios." >&2
  exit 1
fi
# Prefer an installed iPhone simulator, without assuming its name/model.
device_id="$(printf '%s' "$devices_json" | python3 -c '
import json, sys
try:
    payload = json.load(sys.stdin)
    if not isinstance(payload, dict) or not isinstance(payload.get("devices"), dict):
        raise ValueError("missing devices")
except (ValueError, TypeError):
    sys.exit("iOS Simulator devolvió una respuesta inválida; no se iniciaron las pruebas.")
for runtime, devices in payload["devices"].items():
    if "iOS" not in runtime:
        continue
    for device in devices:
        if device.get("isAvailable") and device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit(0)
sys.exit("No hay un simulador iPhone disponible. Instala iOS Simulator en Xcode.")
')"
xcodebuild test -project PinHaven.xcodeproj -scheme PinHaven \
  -destination "platform=iOS Simulator,id=$device_id" \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
