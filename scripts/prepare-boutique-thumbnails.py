"""Package approved boutique illustrations without including large masters in the APK."""
from pathlib import Path
import json, shutil
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
master=ROOT/'design/store-boutique'
out=ROOT/'assets/images/products/boutique'
out.mkdir(parents=True,exist_ok=True)
sources=json.loads((master/'catalog-sources.json').read_text(encoding='utf-8'))
report=[]
for key,meta in sources.items():
    source=master/(key+'.png')
    if not source.exists(): shutil.copy2(meta['source'],source)
    image=Image.open(source).convert('RGBA')
    if image.getextrema()[3][0] != 0: raise ValueError(key+': missing transparent margin')
    image.thumbnail((640,640),Image.Resampling.LANCZOS)
    target=out/(key+'.webp')
    if not target.exists(): image.save(target,format='WEBP',quality=93,method=6)
    report.append({'key':key,'bytes':target.stat().st_size,'size':image.size})
review=ROOT/'outputs/store-boutique';review.mkdir(parents=True,exist_ok=True)
for page in range((len(report)+11)//12):
    sheet=Image.new('RGB',(1200,900),'#fff8f3');draw=ImageDraw.Draw(sheet)
    for i,row in enumerate(report[page*12:(page+1)*12]):
        im=Image.open(out/(row['key']+'.webp')).convert('RGBA');im.thumbnail((270,240),Image.Resampling.LANCZOS)
        x=(i%4)*300+(300-im.width)//2;y=(i//4)*300+10
        sheet.paste(im,(x,y),im);draw.text(((i%4)*300+15,(i//4)*300+265),row['key'],fill='#302831')
    sheet.save(review/('contact-'+str(page+1)+'.jpg'),quality=92)
(review/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(str(len(report))+' illustrations; '+str(sum(r['bytes'] for r in report))+' runtime bytes')
