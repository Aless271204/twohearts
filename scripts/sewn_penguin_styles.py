"""Derive styles from the actual approved penguin shirt, including its skin field."""
import json, struct, hashlib
import bpy
from wardrobe_gltf import _attribute, add_skin_attributes
from sewn_wardrobe_patterns import finish_and_fit
from approved_shirt_coverage import update

def build(base,root,item):
 source=root/'assets/runner/accessories/sewn_shirt_love_penguin.glb'
 blob=source.read_bytes();length=struct.unpack_from('<I',blob,12)[0]
 doc=json.loads(blob[20:20+length]);binary=blob[28+length:]
 primary=next(m for m in doc['meshes'] if m['name'].startswith('Manga adaptada'))
 names=primary['extras']['nidoBoneNames'];field=[]
 for primitive in primary['primitives']:
  attrs=primitive['attributes'];points=_attribute(doc,binary,attrs['POSITION']);joints=_attribute(doc,binary,attrs['JOINTS_0']);weights=_attribute(doc,binary,attrs['WEIGHTS_0'])
  for p,j,w in zip(points,joints,weights):
   mapping={names[k]:v for k,v in zip(j,w)}
   left=mapping.get('NidoLeftSleeve',0);right=mapping.get('NidoRightSleeve',0);arm=left+right
   neck=sum(v for k,v in mapping.items() if k.endswith('Neck'))
   field.append([*p,1 if left>=right else -1,arm,neck/max(1-arm,1e-8)])
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(source))
 meshes=[o for o in bpy.data.objects if o.type=='MESH']
 cloth=next(o for o in meshes if o.name.replace('_',' ').startswith('Manga adaptada'))
 heart=next(o for o in meshes if 'Bordado' in o.name)
 parts=[cloth,heart]+[o for o in meshes if o not in (cloth,heart)]
 data=json.loads((root/'design/wardrobe-restart/fitting/penguin-original.json').read_text(encoding='utf-8'))
 parts,data,field,dims=finish_and_fit(base,parts,data,field,'penguin',item,root)
 data['garment_skin_profile']={'shoulder_start':dims['shoulder_start'],'sleeve_full':dims['sleeve_full'],
  'sleeve_min_y':dims['sleeve_min_y'],'sleeve_fade_y':.06,'stable_torso':True,'preserve_torso_surface':True,'surface_sleeve_anchors':True,
  'volumetric_sleeves':dims['sleeve_volume'],'sewn_sleeve_field':field,'sewn_surface_skin':False,
  'sewn_neck_joint':True,'preserve_authored_sleeve_contact':True,'field_pre_smoothed':True,
  'continuous_neck_binding':{'lower':dims['top']-.040,'upper':dims['top']}}
 update(data,True,'penguin',dims,item)
 path=root/f'assets/runner/accessories/sewn_{item}_penguin.glb';stage=path.with_suffix('.building.glb')
 base.export_selected(stage,parts,False);add_skin_attributes(stage,data);stage.replace(path)
 bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(root/f'design/wardrobe-restart/models/COSIDO-{item}-penguin.blend'),compress=True)
 catalog=root/'assets/runner/restart/catalog.json';registry=json.loads(catalog.read_text(encoding='utf-8'))
 row=next(i for i in registry['wardrobe'] if i['item_key']==item)
 variant=next(v for v in row['variants'] if v['species']=='penguin')
 variant.update(original_asset=path.relative_to(root).as_posix(),original_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
  coverage_asset=f'assets/runner/restart/sewn-coverage-penguin-{item}.json',fit_status='approved_shirt_derived_in_review')
 catalog.write_text(json.dumps(registry,ensure_ascii=False,indent=2),encoding='utf-8')
 print('APPROVED_PATTERN_STYLE_EXPORTED',item,flush=True)
