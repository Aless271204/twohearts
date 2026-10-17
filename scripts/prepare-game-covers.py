"""Encode approved generated covers for the mobile game hub."""
from pathlib import Path
import shutil
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
sources={
 'art-game-cover':r'C:\Users\Lenovo\.codex\generated_images\01a119dd-fbd0-7490-9d7e-2daf0e5cab9d\exec-9773986c-579e-4aed-a652-0ef7f2a86607.png',
}
for name,path in sources.items():
 master=ROOT/'design/art-references'/(name+'.png')
 if not master.exists(): shutil.copy2(path,master)
 image=Image.open(master).convert('RGB');image.thumbnail((960,640),Image.Resampling.LANCZOS)
 image.save(ROOT/'assets/images/ui'/(name+'.webp'),format='WEBP',quality=90,method=6)
