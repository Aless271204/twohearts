"""Check the signed AAB identity, actual game assets and 64-bit ELF alignment."""
import hashlib,json,re,struct,subprocess,sys,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
p=Path(sys.argv[1]);report={'file':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
cert=subprocess.run(['keytool','-J-Duser.language=en','-printcert','-jarfile',str(p)],text=True,capture_output=True,check=True).stdout
match=re.search(r'SHA256:\s*([A-Fa-f0-9:]+)',cert);assert match,'No signing certificate'
fingerprint=match[1].replace(':','').lower()
assert fingerprint=='6991bdb5af84789e9770c5cbe43b6bd0e9aec9a2d0a8c0947c1b8ee79cf908a5','Upload signing identity changed'
report['certificate_sha256']=fingerprint
with zipfile.ZipFile(p) as z:
 assert z.testzip() is None,'Invalid archive'
 manifest=z.read('base/manifest/AndroidManifest.xml')
 assert b'app.nido.twohearts' in manifest,'Wrong application ID'
 assert b'1.3.3' in manifest,'Wrong version name'
 assert b'com.android.vending.BILLING' in manifest,'Missing Play Billing permission'
 native=[]
 for name in z.namelist():
  if name.endswith('.so') and ('/arm64-v8a/' in name or '/x86_64/' in name):
   b=z.read(name);assert b[:4]==b'\x7fELF' and b[4]==2 and b[5]==1,name
   off=struct.unpack_from('<Q',b,32)[0];size,count=struct.unpack_from('<HH',b,54)
   for i in range(count):
    ph=off+i*size
    if struct.unpack_from('<I',b,ph)[0]==1:
     fileoff,vaddr=struct.unpack_from('<QQ',b,ph+8);alignment=struct.unpack_from('<Q',b,ph+48)[0]
     assert alignment>=16384 and (vaddr-fileoff)%16384==0,'16 KB incompatible: '+name
   native.append(name)
 assert any('/arm64-v8a/' in n for n in native),'Missing 64-bit support'
 verified=0
 for folder in ('snow','guardian','penalties','maze'):
  for source in (ROOT/'assets/runner'/folder).iterdir():
   if source.is_file() and source.suffix in ('.js','.html','.webp','.mp3'):
    local=source.read_bytes();packed=z.read('base/assets/flutter_assets/'+source.relative_to(ROOT).as_posix())
    if source.suffix in ('.js','.html'):local=local.replace(b'\r\n',b'\n');packed=packed.replace(b'\r\n',b'\n')
    assert local==packed,'Stale bundled game asset: '+str(source)
    verified+=1
 report.update(native_64bit_libraries=len(native),elf_16kb_alignment=True,game_assets_verified=verified,production_ready=False)
Path('outputs/play-candidate').mkdir(parents=True,exist_ok=True)
Path('outputs/play-candidate/verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report,indent=2))
