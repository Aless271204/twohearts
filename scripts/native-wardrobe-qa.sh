#!/usr/bin/env bash
set -euo pipefail
mkdir -p outputs/native-beret-fit
flutter test integration_test/beret_fit_test.dart -d emulator-5554 --reporter expanded 2>&1 | while IFS= read -r line; do
  printf '%s\n' "$line"
  if [[ "$line" =~ QA_FRAME=([a-zA-Z0-9_]+) ]]; then
    adb -s emulator-5554 exec-out screencap -p > "outputs/native-beret-fit/${BASH_REMATCH[1]}.png"
  fi
done
