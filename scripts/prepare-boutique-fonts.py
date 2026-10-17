"""Bundle the open-source typefaces and their SIL Open Font Licenses."""
from pathlib import Path
from urllib.request import urlopen
from urllib.parse import quote
ROOT=Path(__file__).resolve().parents[1]
target=ROOT/'assets/fonts';target.mkdir(parents=True,exist_ok=True)
for folder,files in {
 'dmsans':['DMSans[opsz,wght].ttf','OFL.txt'],
 'playfairdisplay':['PlayfairDisplay[wght].ttf','PlayfairDisplay-Italic[wght].ttf','OFL.txt'],
}.items():
 for file in files:
  name=folder+'-OFL.txt' if file=='OFL.txt' else file
  dest=target/name
  if not dest.exists():
   url='https://raw.githubusercontent.com/google/fonts/main/ofl/'+folder+'/'+quote(file)
   with urlopen(url,timeout=45) as response: data=response.read()
   assert len(data)>1000,file
   dest.write_bytes(data)
print('Fonts and licenses ready')
