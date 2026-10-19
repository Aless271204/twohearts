from pathlib import Path
from PIL import Image
import json,hashlib,shutil,sys,subprocess

generated=Path('C:/Users/Lenovo/.codex/generated_images/01a119dd-fbd0-7490-9d7e-2daf0e5cab9d')
sources={'penguin':'exec-52d8f9fa-28b4-42c0-aa5f-83af68bbd3e6.png','bear':'exec-0fd4d501-828f-44f6-b176-9cdcf64f408c.png','pig':'exec-3851afb3-14f7-4926-9ee9-857289d73fdd.png','chick':'exec-6ad363e2-bee9-4e17-878d-16097168cc40.png'}
design=Path('design/adoption-story-v3');design.mkdir(parents=True,exist_ok=True)
assets=Path('assets/images/ui');files=[]
for species,source in sources.items():
    shutil.copy2(generated/source,design/(species+'-stork-atlas.png'))
    im=Image.open(generated/source).convert('RGB');w,h=im.size
    for i in range(4):
        box=(i%2*w//2,i//2*h//2,(i%2+1)*w//2,(i//2+1)*h//2)
        dst=assets/f'adoption-{species}-{i}-v3.webp';im.crop(box).save(dst,'WEBP',quality=88,method=6)
        files.append(dict(species=species,frame=i,path=str(dst),crop=box,bytes=dst.stat().st_size,sha256=hashlib.sha256(dst.read_bytes()).hexdigest()))
welcome=generated/'exec-0bdfec69-e174-4cb6-82a9-f549aa704c0e.png';shutil.copy2(welcome,design/'welcome-original.png')
im=Image.open(welcome).convert('RGB');im.thumbnail((900,1350));dst=assets/'adoption-welcome-v3.webp';im.save(dst,'WEBP',quality=87,method=6)
files.append(dict(path=str(dst),bytes=dst.stat().st_size,sha256=hashlib.sha256(dst.read_bytes()).hexdigest()))
(design/'art-manifest.json').write_text(json.dumps(dict(tool='Built-in image_gen',bird='stork',frames=files),indent=2))

# Round off the piercing upper partials while retaining each animal's identity.
sys.path.insert(0,str(Path('tools/audio-runtime').resolve()))
import imageio_ffmpeg
audio=[]
for species,ratio,cutoff in [('penguin',.76,1850),('bear',.93,2000),('pig',.87,1750),('chick',.72,1650)]:
    src=design/'audio-originals'/(species+'.mp3');dst=Path('assets/sounds')/f'adoption_baby_{species}_v3.mp3'
    filters=f'asetrate=44100*{ratio},aresample=22050,atempo={1/ratio:.5f},highpass=f=110,lowpass=f={cutoff},acompressor=threshold=0.12:ratio=2:attack=15:release=90,volume=0.52,afade=t=in:d=0.09,afade=t=out:st=1.7:d=0.3'
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-hide_banner','-loglevel','error','-y','-i',str(src),'-af',filters,'-ac','1','-b:a','48k',str(dst)],check=True)
    audio.append(dict(species=species,path=str(dst),pitch_ratio=ratio,lowpass_hz=cutoff,bytes=dst.stat().st_size,sha256=hashlib.sha256(dst.read_bytes()).hexdigest()))
(design/'softened-audio-manifest.json').write_text(json.dumps(audio,indent=2))
print(json.dumps(dict(images=len(files),image_bytes=sum(f['bytes'] for f in files),audio_bytes=sum(f['bytes'] for f in audio))))
