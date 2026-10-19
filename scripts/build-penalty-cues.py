"""Small original synthesized referee/countdown cues; no external recordings."""
from pathlib import Path
import math, random, wave, struct, json

RATE = 24000
OUT = Path(__file__).resolve().parents[1] / 'assets/sounds'
PREVIEW = Path(__file__).resolve().parents[1] / 'design/new-games/penalty-audio'
OUT.mkdir(parents=True, exist_ok=True)
PREVIEW.mkdir(parents=True, exist_ok=True)

def envelope(t, duration, attack=.012, release=.06):
    return max(0, min(1, t / attack, (duration-t) / release))

def cue(name, duration):
    noise=random.Random(184);phase=0;result=[]
    for i in range(round(RATE*duration)):
        t=i/RATE; env=envelope(t,duration)
        if name=='whistle':
            freq=2070+110*math.sin(2*math.pi*22*t)
            phase+=2*math.pi*freq/RATE
            breath=(noise.random()*2-1)*.05
            value=(math.sin(phase)*.20+math.sin(phase*1.46)*.055+breath)*env*(.8+.2*math.sin(2*math.pi*17*t))
        elif name=='tick':
            phase+=2*math.pi*660/RATE
            value=(math.sin(phase)*.29+math.sin(phase*2.76)*.07)*math.exp(-t*27)*env
        else:
            freq=440*math.exp(-t*2.8);phase+=2*math.pi*freq/RATE
            value=(math.sin(phase)*.23+math.sin(phase*2)*.035)*env
        result.append(value)
    return result

def write(path,data):
    assert max(abs(v) for v in data)<.95
    with wave.open(str(path),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE)
        f.writeframes(struct.pack('<'+'h'*len(data),*(round(max(-1,min(1,v))*32767) for v in data)))

clips={name:cue(name,seconds) for name,seconds in [('whistle',.58),('tick',.16),('timeup',.48)]}
manifest=[]
for name,data in clips.items():
    target=OUT/f'penalty_{name}.wav';write(target,data)
    manifest.append(dict(file=target.name,seconds=len(data)/RATE,peak=round(max(abs(v) for v in data),4),bytes=target.stat().st_size))
preview=[0.]*(RATE*7)
for n in range(5):
    at=round((.4+n)*RATE)
    for j,v in enumerate(clips['tick']):preview[at+j]+=v
for offset,name in [(5.4,'timeup'),(6.1,'whistle')]:
    at=round(offset*RATE)
    for j,v in enumerate(clips[name]):preview[at+j]+=v
write(PREVIEW/'contador-y-silbato.wav',preview)
(PREVIEW/'manifest.json').write_text(json.dumps(dict(origin='Original procedural synthesis, not a recording',sample_rate=RATE,clips=manifest),indent=2),encoding='utf-8')
print(json.dumps(manifest))
