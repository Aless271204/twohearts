#!/usr/bin/env bash
set -euo pipefail
mkdir -p outputs/play-listing-screens
adb -s emulator-5554 shell wm size 1080x1920
adb -s emulator-5554 shell wm density 420
flutter test integration_test/play_listing_android_test.dart -d emulator-5554 --dart-define-from-file=build-env.json --reporter expanded 2>&1 | while IFS= read -r line; do
  printf '%s\n' "$line"
  if [[ "$line" =~ QA_FRAME=(nido_welcome|nido_login) ]]; then
    adb -s emulator-5554 exec-out screencap -p > "outputs/play-listing-screens/${BASH_REMATCH[1]}.png"
  fi
done
test -s outputs/play-listing-screens/nido_welcome.png
test -s outputs/play-listing-screens/nido_login.png
