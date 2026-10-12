"""Share identical texture bytes across species GLBs, with no resizing or recompression."""
import json, struct, hashlib
from pathlib import Path
repo=Path(__file__).resolve().parents[1]
report_path=repo/'design/blender/fitting/tailoring-report.json'
report=json.loads(report_path.read_text(encoding='utf-8'))
before=after=0;shared={}
for entry in report:
    path=repo/entry['path'];data=path.read_bytes();before+=len(data)
    json_length=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+json_length]);binary=data[28+json_length:]
    image_views=set()
    for image in doc.get('images',[]):
        if 'bufferView' not in image:continue
        index=image.pop('bufferView');image_views.add(index);view=doc['bufferViews'][index]
        blob=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
        digest=hashlib.sha256(blob).hexdigest();ext={'image/png':'png','image/jpeg':'jpg','image/webp':'webp'}[image['mimeType']]
        name='head_texture_'+digest[:20]+'.'+ext
        texture=path.parent/name
        if not texture.exists():texture.write_bytes(blob)
        assert hashlib.sha256(texture.read_bytes()).hexdigest()==digest
        image['uri']=name;shared[name]=len(blob)
    if image_views:
        new_binary=bytearray();views=[];mapping={}
        for i,view in enumerate(doc['bufferViews']):
            if i in image_views:continue
            while len(new_binary)%4:new_binary.append(0)
            offset=len(new_binary);chunk=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']];new_binary.extend(chunk)
            mapping[i]=len(views);views.append({**view,'byteOffset':offset})
        for accessor in doc['accessors']:
            if 'bufferView' in accessor:accessor['bufferView']=mapping[accessor['bufferView']]
            if 'sparse' in accessor:
                for part in ('indices','values'):accessor['sparse'][part]['bufferView']=mapping[accessor['sparse'][part]['bufferView']]
        doc['bufferViews']=views;doc['buffers'][0]['byteLength']=len(new_binary)
        while len(new_binary)%4:new_binary.append(0)
        chunk=json.dumps(doc,separators=(',',':')).encode();chunk+=b' '*((-len(chunk))%4)
        data=struct.pack('<III',0x46546C67,2,28+len(chunk)+len(new_binary))+struct.pack('<II',len(chunk),0x4E4F534A)+chunk+struct.pack('<II',len(new_binary),0x004E4942)+new_binary
        path.write_bytes(data)
    entry['sha256']=hashlib.sha256(data).hexdigest();entry['shared_textures']=[i['uri'] for i in doc.get('images',[])];after+=len(data)
report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'glb_before_bytes':before,'glb_after_bytes':after,'shared_texture_bytes':sum(shared.values()),'unique_textures':len(shared),'total_after_bytes':after+sum(shared.values())}))
