"""Original compact scores and action foley for NIDO; no downloaded music."""
import sys, math, json, wave, subprocess, hashlib
from pathlib import Path
import numpy as np
sys.path.insert(0,str(Path('tools/audio-runtime').resolve()))
import imageio_ffmpeg
RATE=22050
OUT=Path('assets/sounds'); TMP=Path('outputs/scene-audio'); TMP.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(84319)
manifest=[]

def save(name,signal):
    peak=max(.01,float(np.max(np.abs(signal))))
    signal=np.tanh(signal/peak*1.1)*.78
    fade=min(440,len(signal)//10);ramp=np.linspace(0,1,fade)
    signal[:fade]*=ramp;signal[-fade:]*=ramp[::-1]
    source=TMP/(name+'.wav');target=OUT/(name+'.mp3')
    with wave.open(str(source),'wb') as f:
        f.setparams((1,2,RATE,len(signal),'NONE','not compressed'));f.writeframes((signal*32767).astype('<i2').tobytes())
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-hide_banner','-loglevel','error','-y','-i',str(source),'-codec:a','libmp3lame','-b:a','64k' if 'theme' in name else '48k',str(target)],check=True)
    manifest.append(dict(file=str(target),bytes=target.stat().st_size,seconds=round(len(signal)/RATE,3),sha256=hashlib.sha256(target.read_bytes()).hexdigest(),peak=round(float(np.max(np.abs(signal))),3),rms=round(float(np.sqrt(np.mean(signal**2))),4)))

def add(out,signal,start):
    indices=(int(start*RATE)+np.arange(len(signal)))%len(out)
    np.add.at(out,indices,signal)

def instrument(note,duration,kind,volume):
    t=np.arange(int(duration*RATE))/RATE;freq=440*2**((note-69)/12)
    if kind=='bell':s=(np.sin(2*np.pi*freq*t)+.22*np.sin(2*np.pi*freq*2.01*t))*np.exp(-t*5/duration)*(1-np.exp(-t*160))
    elif kind=='pad':s=(np.sin(2*np.pi*freq*t)+.18*np.sin(2*np.pi*freq*2*t))*np.sin(np.pi*t/duration)**2
    elif kind=='flute':s=(np.sin(2*np.pi*freq*t+.015*np.sin(2*np.pi*5*t))+.08*np.sin(2*np.pi*freq*2*t))*(1-np.exp(-t*35))*np.minimum(1,(duration-t)/.1)*np.exp(-t*.5)
    else:s=(np.sin(2*np.pi*freq*t)+.12*np.sin(2*np.pi*freq*2*t))*np.exp(-t*6/duration)*(1-np.exp(-t*180))
    return s*volume

for name,bpm,chords,melody in [
 ('penalty_theme',112,[[55,59,62],[52,55,59],[48,52,55],[50,54,57]],[[79,0,78,74,76,74,71,0],[76,0,74,71,74,76,79,0],[72,0,76,79,76,74,72,0],[74,0,78,81,79,78,74,0]]),
 ('maze_theme',82,[[50,57,60],[53,57,60],[55,59,62],[48,55,58]],[[74,0,77,0,76,0,69,0],[72,0,69,0,65,0,69,0],[74,0,71,0,79,0,74,0],[70,0,67,0,74,0,72,0]])]:
    beat=60/bpm;length=beat*4*8;out=np.zeros(round(length*RATE))
    for bar in range(8):
        chord=chords[bar%4]
        for n in chord:add(out,instrument(n,beat*4,'pad',.08),bar*beat*4)
        for step in range(8):
            at=bar*beat*4+step*beat/2
            add(out,instrument(chord[step%3]+12,beat*.7,'bell',.10 if name=='penalty_theme' else .065),at)
            n=melody[bar%4][step]
            if n:add(out,instrument(n,beat*.85,'flute' if name=='penalty_theme' else 'bell',.13),at)
            if step%2==0:
                add(out,instrument(chord[0]-12,beat*.65,'bass',.16),at)
                t=np.arange(int(RATE*.14))/RATE
                drum=np.sin(2*np.pi*(95*t-130*t*t))*np.exp(-t*28)*.14
                if step%4==2:drum+=rng.normal(0,.06,len(t))*np.exp(-t*34)
                if name=='penalty_theme':add(out,drum,at)
    save(name,out)

for i in range(3):
    t=np.arange(int(RATE*.13))/RATE
    s=rng.normal(0,.23,len(t))*np.exp(-t*43)*(1-np.exp(-t*250))+np.sin(2*np.pi*(80+i*11)*t)*np.exp(-t*45)*.23
    save('maze_step_'+str(i),s)
for name,duration in [('maze_chest',.6),('maze_trap',.55),('maze_disarm',.55),('scene_click',.09),('maze_light',.16),('maze_blocked',.12)]:
    t=np.arange(int(RATE*duration))/RATE
    freq=90 if name=='maze_chest' else 46 if name=='maze_trap' else 310 if name=='maze_disarm' else 180
    s=np.sin(2*np.pi*(freq*t+12*t*t))*np.exp(-t*8/duration)*.22
    s+=rng.normal(0,.1,len(t))*np.exp(-t*13/duration)
    if name=='maze_chest':s+=np.sin(2*np.pi*320*t)*np.exp(-t*3/duration)*.045
    save(name,s)
Path('design/game-audio-v1').mkdir(parents=True,exist_ok=True)
Path('design/game-audio-v1/original-score-manifest.json').write_text(json.dumps(dict(provenance='Original locally composed scores and synthesized foley, deterministic seed84319',files=manifest),indent=2))
print(json.dumps(dict(files=len(manifest),bytes=sum(p['bytes'] for p in manifest))))
