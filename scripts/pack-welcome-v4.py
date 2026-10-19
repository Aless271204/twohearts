from pathlib import Path
from PIL import Image
import hashlib,json,shutil
root=Path(__file__).resolve().parents[1]
generated=Path('C:/Users/Lenovo/.codex/generated_images/01a119dd-fbd0-7490-9d7e-2daf0e5cab9d')
names=['exec-d539cf0f-f2ed-46f6-bdf9-827f9843729b.png','exec-072aae6b-8f6c-4ad4-94c9-125bf67a8837.png','exec-3d72b768-f5ae-44fc-83f7-368b09721ce6.png','exec-67251b14-3c56-4cad-b4d4-3b56f5ace110.png','exec-ecc456a3-7c8a-4879-8afd-560ef3b8fde3.png']
manifest=[]
for i,name in enumerate(names):
 source=generated/name;shutil.copy2(source,root/f'design/welcome-v4/section-{i}.png')
 im=Image.open(source).convert('RGB');im.thumbnail((800,1200))
 target=root/f'assets/images/ui/login-welcome-{i}-v4.webp';im.save(target,'WEBP',quality=86,method=6)
 manifest.append(dict(frame=i,path=str(target.relative_to(root)),size=im.size,bytes=target.stat().st_size,sha256=hashlib.sha256(target.read_bytes()).hexdigest()))
(root/'design/welcome-v4/manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps(dict(images=len(manifest),bytes=sum(f['bytes'] for f in manifest))))
