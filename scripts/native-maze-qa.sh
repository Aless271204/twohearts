#!/usr/bin/env bash
set -euo pipefail
mkdir -p outputs/native-maze
QA_OUTPUT="$PWD/outputs/native-maze"
cd "$RUNNER_TEMP/nido-fit"
flutter test integration_test/maze_android_test.dart -d emulator-5554 --reporter expanded 2>&1 | while IFS= read -r line; do
  printf '%s\n' "$line"
  if [[ "$line" =~ QA_FRAME=([a-zA-Z0-9_]+) ]]; then
    adb -s emulator-5554 exec-out screencap -p > "$QA_OUTPUT/${BASH_REMATCH[1]}.png"
  fi
done
