#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Se requiere un Mac con Xcode y un runtime de iOS Simulator instalado." >&2
  exit 1
fi
# Prefer an installed iPhone simulator, without assuming its name/model.
device_id="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
payload = json.load(sys.stdin)
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
