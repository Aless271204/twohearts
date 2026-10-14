"""Refresh removable masks without rebuilding any pet or garment geometry."""
import json
from pathlib import Path
from approved_shirt_coverage import update
ROOT=Path(__file__).resolve().parents[1]
patterns=json.loads((ROOT/'design/wardrobe-restart/original-shirt-patterns.json').read_text(encoding='utf-8'))['species']
fits=json.loads((ROOT/'design/wardrobe-restart/sewn-species-fit.json').read_text(encoding='utf-8'))['species']
for sp in ('bear','pig','chick'):
    cfg=patterns[sp];data=json.loads((ROOT/f'design/wardrobe-restart/fitting/{sp}-original.json').read_text(encoding='utf-8'))
    for item in ('shirt_love','jacket_denim','coat_cloud','dress_petal','hoodie_nido'):
        dim={'hem':cfg['hem'],'top':fits[sp]['collar_top'],'shoulder_start':cfg['shoulder_start'],'cuff_x':cfg['cuff_center'][0],'cuff_y':cfg['cuff_center'][1]-{'jacket_denim':.025,'coat_cloud':.050,'hoodie_nido':.045}.get(item,0),'cuff_slope':.012*(fits[sp]['collar_top']-cfg['hem'])/.305/(.055*cfg['sleeve_radius'][0]/.095)}
        update(data,True,sp,dim,item)
print('15 removable clothing masks refreshed; original face vertices retained')
