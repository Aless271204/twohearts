"""Record the manually inspected native frames; reject loading-screen captures."""
import hashlib,json,subprocess
from pathlib import Path
from datetime import datetime,timezone
from PIL import Image,ImageOps,ImageDraw
root=Path(__file__).resolve().parents[1];frames=[];models={};pets={}
def sha(data):return hashlib.sha256(data).hexdigest()
for species,original in {'penguin':'Meshy_AI_Pip_the_Penguin_All_Animations.glb','bear':'bear.glb','pig':'pig.glb','chick':'chick.glb'}.items():
    asset=f'assets/runner/accessories/experimental_beret_chic_{species}_v9.glb'
    data=(root/asset).read_bytes()
    assert data==subprocess.check_output(['git','show','c648c5102d2388817c3503978b858c756f0409bc:'+asset],cwd=root)
    models[species]=sha(data)
    pet='assets/runner/play-models/'+original
    before=subprocess.check_output(['git','show','fd2c5306414459a0491a80cda34b545fc11f3b5a:'+pet],cwd=root)
    assert (root/pet).read_bytes()==before
    pets[species]=sha(before)
    for pose in ['Rest_0','Rest_90','Rest_180','Running_0','Regular_Jump_0']:
        run='39629426173' if pose!='Running_0' else ('39634660827' if species=='penguin' else '39631697533')
        file=root/f'outputs/native-beret-fit/{run}/{species}_{pose}.png'
        data=file.read_bytes()
        assert len(data)>10000, 'Loading-screen-sized capture: '+str(file)
        frames.append({'species':species,'pose':pose,'run':run,'path':str(file.relative_to(root)).replace('\\','/'),'sha256':sha(data)})
receipt={'visual_reviewed':True,'asset_commit':'c648c5102d2388817c3503978b858c756f0409bc',
 'capture_commits':['c648c5102d2388817c3503978b858c756f0409bc','efbb4325164e007fcdc26945f0415bc04a8b1387','bfd9834d6ff2f7cb96b8828f996c63c48e4dc9d8'],
 'source':'isolated Android host using the app renderer, original pets and original animation clips',
 'scope':'front/profile/back and fixed run/jump sample; not a certification of every animation frame',
 'findings':['crown narrower than the skull','asymmetric felt volume and folds visible','ears visible','attachment follows reviewed movement samples'],
 'reviewed_at':datetime.now(timezone.utc).isoformat(),'models':models,'original_pets_unchanged':pets,'frames':frames}
(root/'outputs/native-beret-fit/validated.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
sheet=Image.new('RGB',(1500,2000),'white');draw=ImageDraw.Draw(sheet)
for index,frame in enumerate(frames):
    x=index%5*300;y=index//5*500
    tile=ImageOps.contain(Image.open(root/frame['path']).convert('RGB'),(300,465))
    sheet.paste(tile,(x,y));draw.text((x+4,y+470),frame['species']+' '+frame['pose'],fill='black')
sheet.save(root/'outputs/native-beret-fit/validated-contact.png')
print('Recorded 20 reviewed native frames; original pet binaries unchanged.')
