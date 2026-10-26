#!/usr/bin/env bash
set -euo pipefail
mkdir -p outputs/play-android-followup
adb -s emulator-5554 shell wm size 1080x1920
adb -s emulator-5554 shell wm density 420
adb -s emulator-5554 shell getprop > outputs/play-android-followup/device-properties.txt
for target in play_listing_android_test snow_android_test; do
 flutter test integration_test/${target}.dart -d emulator-5554 --dart-define-from-file=build-env.json --reporter expanded 2>&1 | tee outputs/play-android-followup/${target}.log | while IFS= read -r line; do
  printf '%s\n' "$line"
  if [[ "$line" =~ QA_FRAME=([a-zA-Z0-9_]+) ]]; then
   adb -s emulator-5554 exec-out screencap -p > "outputs/play-android-followup/${BASH_REMATCH[1]}.png"
  fi
 done
done
