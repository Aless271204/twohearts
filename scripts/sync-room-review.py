"""Regenerate the browser review catalog from the editable Flutter catalog."""
import json
import pathlib
import re

repo = pathlib.Path(__file__).resolve().parents[1]
text = (repo / 'lib/core/room_catalog.dart').read_text(encoding='utf-8')
rows = re.findall(r"roomItem\(\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*(\d+)", text)
if not rows:
    raise ValueError('No room entries found; review the Dart catalog syntax')
items = [dict(item_key=k, name=n, equip_slot=s, room_category=c,
              appearance=dict(style=t, color=v)) for k, n, s, c, t, v, _ in rows]
if len({i['item_key'] for i in items}) != len(items):
    raise ValueError('Duplicate item_key')
(repo / 'assets/runner/room-catalog.json').write_text(
    json.dumps(items, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'{len(items)} room products synchronized')
