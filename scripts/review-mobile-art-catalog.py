"""Validate inventory and render contact sheets of actual packaged assets for review."""
import json, collections, html
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
items=json.loads((ROOT/'assets/images/art_references/mobile/catalog.json').read_text(encoding='utf-8'))
active=[x for x in items if x['enabled']]
assert len({x['id'] for x in items})==len(items)
assert len(active)==60
out=ROOT/'outputs/art-catalog-review';out.mkdir(parents=True,exist_ok=True)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',14)
for level in ['easy','medium','hard']:
    group=[x for x in active if x['level']==level]
    assert len(group)==20,(level,len(group))
    assert sum(x['category']=='mascots' for x in group)==5,level
    sheet=Image.new('RGB',(1024,1440),'#fff8f6');draw=ImageDraw.Draw(sheet)
    for i,item in enumerate(group):
        image=Image.open(ROOT/item['asset']);assert image.size==(768,768),item['id']
        image=image.convert('RGB');image.thumbnail((248,248))
        x=(i%4)*256+4;y=(i//4)*288+4
        sheet.paste(image,(x,y));draw.text((x+4,y+254),item['title'][:32],font=font,fill='#302831')
    sheet.save(out/(level+'.jpg'),quality=90)
report={'active':len(active),'reserve':len(items)-len(active),'levels':{l:dict(collections.Counter(x['category'] for x in active if x['level']==l)) for l in ['easy','medium','hard']},'runtime_bytes':sum((ROOT/x['asset']).stat().st_size for x in items)}
(out/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
cards=''.join('<section><h2>'+{'easy':'Fácil','medium':'Medio','hard':'Difícil'}[level]+'</h2><div class="grid">'+''.join('<figure><img loading="lazy" src="../../'+html.escape(item['asset'])+'"><figcaption>'+html.escape(item['title'])+'</figcaption></figure>' for item in active if item['level']==level)+'</div></section>' for level in ['easy','medium','hard'])
(out/'catalog.html').write_text('<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>NIDO · Referencias para dibujar</title><style>body{font-family:system-ui;background:#fff8f6;color:#302831;margin:auto;max-width:1200px;padding:24px}h1,h2{color:#bd5476}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:16px}figure{background:white;border-radius:18px;margin:0;padding:8px;box-shadow:0 3px 14px #7c315411}img{display:block;width:100%;border-radius:12px}figcaption{padding:10px;font-size:14px}</style><h1>Pincel en pareja</h1><p>60 referencias · 20 por nivel · 5 con mascotas por nivel</p>'+cards+'</html>',encoding='utf-8')
