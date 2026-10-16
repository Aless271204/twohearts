"""Lossless packaging conversion. Original approved PNG artwork stays in design/."""
from pathlib import Path
import hashlib,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
sources={'forest':'forest-background-v1.png','enemies':'forest-enemies-v1.png','items':'powerups-v1.png','musgo':'moss-isolated-poses-v1.png','tiles':'forest-tiles-v1.png'}
report=[]
for name,filename in sources.items():
 source=ROOT/'design/boss-rush/art-v1'/filename;old=ROOT/'assets/runner/guardian'/(name+'.png');target=old.with_suffix('.webp')
 if old.exists():assert source.read_bytes()==old.read_bytes(),'Original backup differs: '+name
 image=Image.open(source).convert('RGBA');image.save(target,format='WEBP',lossless=True,quality=0,method=0,exact=True)
 decoded=Image.open(target).convert('RGBA');assert image.size==decoded.size and image.tobytes()==decoded.tobytes(),'Pixel difference: '+name
 report.append({'name':name,'source':source.relative_to(ROOT).as_posix(),'asset':target.relative_to(ROOT).as_posix(),'original_bytes':source.stat().st_size,'bytes':target.stat().st_size,'rgba_sha256':hashlib.sha256(image.tobytes()).hexdigest(),'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
(ROOT/'assets/runner/guardian/art-manifest.json').write_text(json.dumps(report,indent=2),encoding='utf8')
for name in sources:(ROOT/'assets/runner/guardian'/(name+'.png')).unlink(missing_ok=True)
print('Lossless RGBA verified for scenery assets:',sum(r['original_bytes'] for r in report),'->',sum(r['bytes'] for r in report),flush=True)
