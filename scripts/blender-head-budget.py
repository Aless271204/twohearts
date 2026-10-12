"""Apply the mobile budget to thick straw hats in the saved fitting workshop."""
import bpy,json,hashlib
from pathlib import Path
repo=Path(__file__).resolve().parents[1]
report_path=repo/'design/blender/fitting/tailoring-report.json'
report=json.loads(report_path.read_text(encoding='utf-8'))
for entry in report:
    if entry['item_key']!='hat_garden':continue
    col=bpy.data.collections[entry['item_key']+' · '+entry['species']]
    col.hide_viewport=False
    bpy.ops.object.select_all(action='DESELECT')
    for obj in col.objects:
        obj.hide_set(False);obj.select_set(True);bpy.context.view_layer.objects.active=obj
        triangles=sum(len(p.vertices)-2 for p in obj.data.polygons)
        if triangles>22000:
            modifier=obj.modifiers.new('Presupuesto móvil','DECIMATE');modifier.ratio=.65;modifier.use_collapse_triangulate=True
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.data.validate(clean_customdata=True);obj.data.update()
    path=repo/entry['path']
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
    entry['triangles']=sum(len(p.vertices)-2 for obj in col.objects for p in obj.data.polygons)
    entry['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
    print('BUDGET',entry['species'],entry['triangles'])
report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath,compress=True)
