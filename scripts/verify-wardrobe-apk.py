"""Verify delivery contains the actual reviewed models and stable APK signer."""
import hashlib,json,re,struct,sys,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'test'))
from inspect_apk_signer import signer

def manifest_identity(data):
    strings=[];offset=8
    def length8(pos):
        value=data[pos];pos+=1
        if value&128:value=((value&127)<<8)|data[pos];pos+=1
        return value,pos
    while offset<len(data):
        kind,header,size=struct.unpack_from('<HHI',data,offset)
        if kind==1:
            count,_,flags,start=struct.unpack_from('<IIII',data,offset+8)
            for i in range(count):
                relative=struct.unpack_from('<I',data,offset+header+i*4)[0]
                p=offset+start+relative
                if flags&256:
                    _,p=length8(p);n,p=length8(p);strings.append(data[p:p+n].decode('utf-8'))
                else:
                    n=struct.unpack_from('<H',data,p)[0];p+=2
                    if n&32768:n=((n&32767)<<16)|struct.unpack_from('<H',data,p)[0];p+=2
                    strings.append(data[p:p+n*2].decode('utf-16le'))
        elif kind==0x102:
            ext=offset+header;name=struct.unpack_from('<I',data,ext+4)[0]
            if strings[name]=='manifest':
                start,width,count=struct.unpack_from('<HHH',data,ext+8);values={}
                for i in range(count):
                    p=ext+start+i*width;index=struct.unpack_from('<I',data,p+4)[0]
                    value=struct.unpack_from('<I',data,p+16)[0]
                    values[strings[index]]=strings[value] if data[p+15]==3 else value
                return {key:values[key] for key in ('package','versionName','versionCode')}
        if not size:raise ValueError('Invalid Android XML chunk')
        offset+=size
    raise ValueError('APK has no manifest identity')

def verify(apk,previous=None):
    checked=0
    with zipfile.ZipFile(apk) as archive:
        assert archive.testzip() is None,'APK ZIP integrity failure'
        identity=manifest_identity(archive.read('AndroidManifest.xml'))
        expected=re.search(r'^version:\s*([^+\s]+)\+(\d+)',(ROOT/'pubspec.yaml').read_text(),re.M)
        assert identity=={'package':'com.example.twohearts','versionName':expected[1],'versionCode':int(expected[2])},identity
        for file in ('music.js','patterns.js','power-ups.js','difficulty.js','game.js','cosmetics.js','pet-garment-rig.js','pet-garment-colors.js','pet-sleeve-coverage.js','pet-footwear-coverage.js','pet-runner-jump.js','pet-runner-run.js'):
            name='assets/runner/'+file
            local=(ROOT/name).read_text(encoding='utf-8-sig').replace('\r\n','\n')
            packed=archive.read('assets/flutter_assets/'+name).decode('utf-8-sig').replace('\r\n','\n')
            assert packed==local,'Stale packaged renderer: '+file
        assert not any('/runner/guardian/' in name for name in archive.namelist()),'Unreleased prototype was packaged'
        name='assets/runner/pet-garment-binding.js'
        assert archive.read('assets/flutter_assets/'+name).decode('utf-8-sig').replace('\r\n','\n')==(ROOT/name).read_text(encoding='utf-8-sig').replace('\r\n','\n'),'Stale garment binding'
        report=json.loads(archive.read('assets/flutter_assets/assets/images/products/wardrobe-thumbnails.json'))
        assert len(report)==96
        for entry in report:
            for key in ('model','thumbnail'):
                content=archive.read('assets/flutter_assets/'+entry[key])
                assert hashlib.sha256(content).hexdigest()==entry[key+'_sha256'],entry[key]
        canonical=json.loads((ROOT/'assets/runner/accessory-catalog.json').read_text(encoding='utf-8'))
        assert json.loads(archive.read('assets/flutter_assets/assets/runner/accessory-catalog.json'))==canonical
        for item in canonical:
            if not item.get('visible',True):continue
            appearance=item['appearance']
            for species,asset in appearance.get('species_models',{}).items():
                assert hashlib.sha256(archive.read('assets/flutter_assets/'+asset)).hexdigest()==appearance['species_model_hashes'][species],asset
                checked+=1
                raw=archive.read('assets/flutter_assets/'+asset)
                length=struct.unpack_from('<I',raw,12)[0];model=json.loads(raw[20:20+length])
                for image in model.get('images',[]):
                    if 'uri' in image:
                        path=(Path(asset).parent/image['uri']).as_posix()
                        image_bytes=archive.read('assets/flutter_assets/'+path)
                        assert hashlib.sha256(image_bytes).hexdigest()==Path(path).stem,path
        models={path for item in canonical if item.get('visible',True) for path in item['appearance'].get('species_models',{}).values()}
        packed_accessories={n.removeprefix('assets/flutter_assets/') for n in archive.namelist() if n.startswith('assets/flutter_assets/assets/runner/accessories/') and n.endswith('.glb')}
        assert packed_accessories==models,'Retired or missing packaged accessories'
    certificate=signer(apk)
    if previous:assert certificate==signer(previous),'Signing identity changed'
    result={'apk':str(apk),'identity':identity,'bytes':apk.stat().st_size,'models_checked':checked,'thumbnails_checked':len(report),
            'sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'signer_sha256':certificate,'previous_signer_matches':bool(previous)}
    target=ROOT/'outputs/wardrobe-apk-verification.json';target.write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result))

if __name__=='__main__':verify(Path(sys.argv[1]),Path(sys.argv[2]) if len(sys.argv)>2 else None)
