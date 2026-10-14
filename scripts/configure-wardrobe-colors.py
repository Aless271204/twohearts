"""Editable dye bindings to the real GLB materials; no pet textures touched."""
import json,struct
from pathlib import Path
root=Path(__file__).resolve().parents[1]
bindings={
 'cap_pink':('Algodón coral','#F05280'),
 'beanie_cloud':('knit · #FFF2DF','#FFF2DF'),
 'hat_garden':('straw · #B8DCCB','#B8DCCB'),
 'beret_chic':('felt · #BAA2DB','#BAA2DB'),
 'mask_sleep':('cotton · #EFA0AB','#EFA0AB'),
 'scarf_hearts':('knit · #EFA0AB','#EFA0AB'),
 'bandana_sage':('cotton · #B8DCCB','#B8DCCB'),
 'bow_neck':('Algodón coral nuevo','#EC6276'),
 'shirt_love':('Algodón crema grueso','#FFF0D9'),
 'jacket_denim':('denim · #92B9D5','#92B9D5'),
 'coat_cloud':('wool · #B3C4A2','#B3C4A2'),
 'dress_petal':('poplin · #F5A8B6','#F5A8B6'),
 'hoodie_nido':('cotton · #C1ADE2','#C1ADE2'),
 'shoes_heart':('Algodón coral nuevo','#EC6276'),
 'boots_rain':('plastic · #B8DCCB','#B8DCCB'),
 'slippers_cloud':('wool · #FFF2DF','#FFF2DF'),
 'shoes_chic':('cotton · #F05280','#F05280'),
 'sandals_summer':('cotton · #F2B29B','#F2B29B'),
}
path=root/'assets/runner/accessory-catalog.json';rows=json.loads(path.read_text(encoding='utf-8'))
for row in rows:
 if row['item_key'] not in bindings:continue
 name,color=bindings[row['item_key']]
 for sp,model in row['appearance']['species_models'].items():
  raw=(root/model).read_bytes();length=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+length])
  assert name in [m['name'] for m in doc['materials']],(row['item_key'],sp,name)
 row['appearance'].update(color_materials=[name],color_base=color)
 row['color_price_coins']=10
path.write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
print('18 garments support dye on all four original pets')
