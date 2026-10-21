#!/usr/bin/env bash
set -euo pipefail
mkdir -p outputs/native-beret-fit
python3 -c "import json; d=json.load(open('env.json')); json.dump({k:d[k] for k in ['SUPABASE_URL','SUPABASE_ANON_KEY','GOOGLE_WEB_CLIENT_ID'] if k in d},open('build-env.json','w'))"
flutter test integration_test/beret_fit_test.dart -d emulator-5554 --dart-define-from-file=build-env.json --reporter expanded 2>&1 | while IFS= read -r line; do
  printf '%s\n' "$line"
  if [[ "$line" =~ QA_FRAME=([a-zA-Z0-9_]+) ]]; then
    adb -s emulator-5554 exec-out screencap -p > "outputs/native-beret-fit/${BASH_REMATCH[1]}.png"
  fi
done
