"""Deterministic technical preflight, not a compliance or visual certification."""
import json,re,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=(ROOT/'pubspec.yaml').read_text(encoding='utf-8')
missing=[];total=0;files=set()
for raw in re.findall(r'^    - (assets/[^\r\n]+)',spec,re.M):
 p=ROOT/raw
 if not p.exists():missing.append(raw);continue
 for f in (p.iterdir() if p.is_dir() else [p]):
  if f.is_file():files.add(f)
for p in files:total+=p.stat().st_size
assert not missing,'Missing runtime assets: '+str(missing)
assert (ROOT/'assets/runner/snow/engine.js').read_bytes()==(ROOT/'supabase/functions/snow-arena/engine.js').read_bytes()
assert 'snow-game-cover-v2.webp' in (ROOT/'lib/widgets/rose_ui.dart').read_text(encoding='utf-8')
assert 'targetSdk = 36' in (ROOT/'android/app/build.gradle.kts').read_text(encoding='utf-8')
assert 'const purchasesEnabled = false' in (ROOT/'lib/core/store_packages.dart').read_text(encoding='utf-8')
print(json.dumps({'runtime_files':len(files),'runtime_bytes':total,'missing_assets':missing,'payments':'disabled','production_submission':'blocked_until_privacy_deletion_and_device_review'},indent=2))
