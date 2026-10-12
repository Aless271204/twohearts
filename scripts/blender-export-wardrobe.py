"""Export one manually edited collection without rebuilding or discarding its edits.
Blender --background FILE.blend --python scripts/blender-export-wardrobe.py -- ITEM SPECIES
"""
import bpy,json,sys,hashlib
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from wardrobe_gltf import add_skin_attributes
R=Path(__file__).resolve().parents[1]
args=sys.argv[sys.argv.index('--')+1:];key,species=args
settings=json.loads((R/'design/blender/wardrobe-patterns.json').read_text(encoding='utf-8'))
catalog_path=next((R/'assets/runner'/file for file in ('blender-wardrobe-models.json','blender-complement-models.json') if any(i['item_key']==key for i in json.loads((R/'assets/runner'/file).read_text(encoding='utf-8')))),None)
if catalog_path is None or species not in ('penguin','bear','pig','chick'):raise ValueError('Código o especie desconocidos')
catalog=json.loads(catalog_path.read_text(encoding='utf-8'));item=next(i for i in catalog if i['item_key']==key);variant=next(v for v in item['variants'] if v['species']==species)
collection=bpy.data.collections.get(key+' · '+species)
if collection is None:raise ValueError('No se encontró la colección editable')
# Export a temporary evaluated copy, retaining the edited source unchanged.
temporary=bpy.data.collections.new('Exportación temporal');bpy.context.scene.collection.children.link(temporary)
collection.hide_viewport=False;deps=bpy.context.evaluated_depsgraph_get();bpy.ops.object.select_all(action='DESELECT')
for source in collection.objects:
 if source.type not in ('MESH','CURVE'):continue
 source.hide_set(False);evaluated=source.evaluated_get(deps)
 geometry=bpy.data.meshes.new_from_object(evaluated,depsgraph=deps);geometry.transform(source.matrix_world)
 geometry.name=source.name
 copy=bpy.data.objects.new(source.name,geometry);temporary.objects.link(copy);copy.select_set(True)
path=R/variant['path']
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
if item['equip_slot'] not in ('pet_head','pet_eyes'):
 data=json.loads((R/'design/blender/fitting'/(species+'.json')).read_text());add_skin_attributes(path,data)
for item in catalog:
 if item['item_key']!=key:continue
 if key in settings['items']:item['visible']=settings['items'][key].get('visible',True)
 for variant in item['variants']:
  if variant['species']==species:variant['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
catalog_path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
print('MANUAL_PATTERN_EXPORTED',key,species)
