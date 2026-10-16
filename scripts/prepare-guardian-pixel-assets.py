"""Package generated art as small, transparent game atlases; keep masters intact.

Remove disconnected particles crossing cell edges, then nearest-neighbour reduce
to the logical pixel grid. No character is repainted by this packaging step.
"""
from pathlib import Path
from collections import deque
from PIL import Image, ImageFilter, ImageChops
import json, hashlib, sys

SOURCE=Path('design/boss-rush/art-v1')
DEST=Path('assets/runner/guardian')

def clean_cells(image, cols=6, rows=4):
    image=image.convert('RGBA');out=Image.new('RGBA',image.size)
    for row in range(rows):
        for col in range(cols):
            box=(col*image.width//cols,row*image.height//rows,(col+1)*image.width//cols,(row+1)*image.height//rows)
            cell=image.crop(box);w,h=cell.size;alpha=cell.getchannel('A');raw=alpha.tobytes();seen=bytearray(w*h);components=[]
            for start in range(w*h):
                if seen[start] or raw[start]<180:continue
                seen[start]=1;queue=deque([start]);points=[]
                while queue:
                    p=queue.popleft();points.append(p);x=p%w;y=p//w
                    for q in ([p-1] if x else [])+([p+1] if x<w-1 else [])+([p-w] if y else [])+([p+w] if y<h-1 else []):
                        if not seen[q] and raw[q]>=180:seen[q]=1;queue.append(q)
                components.append(points)
            mask=bytearray(w*h)
            for points in components:
                if len(points)>=500 and 32<sum(p%w for p in points)/len(points)<w-10:
                    for p in points:mask[p]=255
            matte=Image.frombytes('L',(w,h),bytes(mask)).filter(ImageFilter.MaxFilter(7))
            cell.putalpha(ImageChops.multiply(alpha,matte));out.paste(cell,box)
    return out

def package():
    selected=set(sys.argv[1:]);manifest=DEST/'wardrobe-art-manifest.json'
    entries=[e for e in json.loads(manifest.read_text()) if e['name'] not in selected] if selected and manifest.exists() else []
    sources=[('pets-base-modular-v1.png','pets-base',True),('inventory-clothing-atlas-v1.png','wardrobe-atlas',False),('musgo-laugh-v1.png','musgo-laugh',False)]
    for key in ['shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido']:
        sources.append(('fitted-'+key+'-v1.png','body-'+key,True))
    for key in ['shoes_heart','boots_rain','slippers_cloud','shoes_chic','sandals_summer']:
        sources.append(('integrated-feet-'+key+'-v1.png','feet-'+key,True))
    ready_heads=json.loads((DEST/'head-fit-manifest.json').read_text(encoding='utf8'))
    for key in ready_heads:
        sources.append(('fitted-head-'+key+'-v1.png','head-'+key,True))
    for filename,name,clean in sources:
        if selected and name not in selected:continue
        source=SOURCE/filename
        if not source.exists():continue
        image=Image.open(source).convert('RGBA')
        if clean:image=clean_cells(image)
        image=image.resize((image.width//2,image.height//2),Image.Resampling.NEAREST)
        destination=DEST/(name+'.webp');temporary=destination.with_suffix('.tmp.webp');image.save(temporary,lossless=True,method=0,quality=0,exact=True);temporary.replace(destination)
        entries.append({'name':name,'source':str(source).replace('\\','/'),'asset':str(destination).replace('\\','/'),'size':image.size,'bytes':destination.stat().st_size,'sha256':hashlib.sha256(destination.read_bytes()).hexdigest()})
    (DEST/'wardrobe-art-manifest.json').write_text(json.dumps(entries,indent=2),encoding='utf8')
    print('Wardrobe atlases:',len(entries),'bytes:',sum(x['bytes'] for x in entries))

if __name__=='__main__':package()
