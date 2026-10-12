"""Repair cloth shell intersections while retaining its original UV/materials."""
import bpy, bmesh

def repair_shell(source):
    if source.get('continuous_shell_v1'):return
    target=source.copy();target.data=source.data.copy();target.modifiers.clear()
    bpy.context.scene.collection.objects.link(target)
    source.hide_set(False);target.hide_set(False)
    bpy.context.view_layer.objects.active=target
    remesh=target.modifiers.new('Costura continua','REMESH')
    remesh.mode='VOXEL';remesh.voxel_size=.0018;remesh.use_smooth_shade=True
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smooth=target.modifiers.new('Tejido redondeado','SMOOTH');smooth.factor=.25;smooth.iterations=2
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    triangles=sum(len(p.vertices)-2 for p in target.data.polygons)
    if triangles>12000:
        decimate=target.modifiers.new('Patrón móvil','DECIMATE');decimate.ratio=12000/triangles
        bpy.ops.object.modifier_apply(modifier=decimate.name)
    if source.data.uv_layers:
        target.data.uv_layers.new(name=source.data.uv_layers.active.name)
        transfer=target.modifiers.new('Conservar tejido original','DATA_TRANSFER')
        transfer.object=source;transfer.use_loop_data=True
        transfer.data_types_loops={'UV'};transfer.loop_mapping='POLYINTERP_NEAREST'
        bpy.ops.object.modifier_apply(modifier=transfer.name)
    mesh=bmesh.new();mesh.from_mesh(target.data)
    bad=sum(not edge.is_manifold for edge in mesh.edges);mesh.free()
    if bad:raise ValueError(f'Cloth shell still has {bad} open/nonmanifold edges: {source.name}')
    for polygon in target.data.polygons:polygon.use_smooth=True
    source.data=target.data;source['continuous_shell_v1']=True
    bpy.data.objects.remove(target,do_unlink=True)
