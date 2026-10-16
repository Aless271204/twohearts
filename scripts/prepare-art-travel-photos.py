"""Package a small, editable Unsplash travel reference selection (not user photos)."""
import concurrent.futures, io, json, urllib.request
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
PHOTOS=[
 ('paris','París · Francia','1502602898657-3e91760cbb34'),
 ('rio','Río de Janeiro · Brasil','1483729558449-99ef09a8c325'),
 ('london','Londres · Inglaterra','1513635269975-59663e0ac1ad'),
 ('giza','Guiza · Egipto','1539768942893-daf53e448371'),
 ('kyoto','Kioto · Japón','1493976040374-85c8e12f0c0e'),
 ('cinque-terre','Cinque Terre · Italia','1516483638261-f4dbaf036963'),
 ('santorini','Santorini · Grecia','1613395877344-13d4a8e0d49e'),
 ('machu-picchu','Machu Picchu · Perú','1526392060635-9d6019884377'),
]
def package(row):
 key,title,photo=row
 url=f'https://images.unsplash.com/photo-{photo}?w=640&h=640&fit=crop&q=85'
 with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'NIDO reference asset preparation'}),timeout=30) as response: data=response.read(4_000_001)
 if len(data)>4_000_000:raise ValueError('Reference too large')
 image=Image.open(io.BytesIO(data)); image.load()
 target=ROOT/'assets/images/art_references'/f'{key}.webp';target.parent.mkdir(parents=True,exist_ok=True)
 ImageOps.fit(image.convert('RGB'),(512,512)).save(target,'WEBP',quality=87,method=6)
 return {'id':key,'title':title,'asset':f'assets/images/art_references/{key}.webp','source':url,'license':'https://unsplash.com/license'}
if __name__=='__main__':
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool: results=list(pool.map(package,PHOTOS))
 folder=ROOT/'design/art-references';folder.mkdir(parents=True,exist_ok=True)
 (folder/'travel-sources.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf8')
 sheet=Image.new('RGB',(1024,560),'#fff7f5');draw=ImageDraw.Draw(sheet)
 for i,r in enumerate(results):
  x=(i%4)*256;y=(i//4)*280
  sheet.paste(Image.open(ROOT/r['asset']).resize((248,248)),(x,y));draw.text((x+4,y+250),r['id'],fill='#302831')
 out=ROOT/'outputs/art-review/travel-bank.jpg';out.parent.mkdir(parents=True,exist_ok=True);sheet.save(out)
 print(json.dumps({'references':len(results),'bytes':sum((ROOT/r['asset']).stat().st_size for r in results)}))
