import math,wave,struct
from pathlib import Path
root=Path('assets/sounds');root.mkdir(exist_ok=True)
rate=22050

def write(name,samples):
 peak=max(1,max(abs(s) for s in samples));data=b''.join(struct.pack('<h',int(max(-1,min(1,s/peak*.85))*32767)) for s in samples)
 with wave.open(str(root/name),'wb') as f:f.setparams((1,2,rate,len(samples),'NONE','not compressed'));f.writeframes(data)

def midi(n):return 440*2**((n-69)/12)
seconds=16;out=[0.0]*int(rate*seconds)
def note(n,start,duration,volume):
 freq=midi(n)
 for j in range(int(duration*rate)):
  k=int(start*rate)+j
  if k>=len(out):break
  t=j/rate;env=(1-math.exp(-t*100))*math.exp(-t*5/duration)
  out[k]+=volume*env*(math.sin(2*math.pi*freq*t)+.16*math.sin(4*math.pi*freq*t))
chords=[[62,66,69],[59,62,66],[55,59,62],[57,61,64]]
melody=[[74,78,81,78],[71,74,78,81],[79,78,74,71],[73,76,81,74]]
for step in range(64):
 bar=step//8;beat=step%8;chord=chords[bar%4];t=step*.25
 note(chord[beat%3],t,.27,.13)
 if beat%2==0:note(melody[bar%4][beat//2],t,.45,.19)
 if beat in(0,4):note(chord[0]-12,t,.45,.18)
 # Original soft hand-drum accent.
 if beat%2==0:
  for j in range(int(rate*.12)):
   k=int(t*rate)+j;v=j/rate
   if k<len(out):out[k]+=.09*math.exp(-v*28)*math.sin(2*math.pi*(120-280*v)*v)
# Smooth loop boundaries without adding an external audio dependency.
for i in range(int(.025*rate)):
 out[i]*=i/(.025*rate);out[-i-1]*=i/(.025*rate)
write('duo_theme.wav',out)
for name,notes in [('duo_hit.wav',[76]),('duo_score.wav',[74,78,81]),('duo_miss.wav',[66,62])]:
 out=[0.0]*int(rate*.35)
 for i,n in enumerate(notes):note(n,i*.065,.18,.35)
 write(name,out)
print('ORIGINAL_GAME_AUDIO_READY',sum(p.stat().st_size for p in root.glob('duo_*.wav')))
p=Path('pubspec.yaml');s=p.read_text(encoding='utf8');marker='  assets:\n';s=s.replace(marker,marker+'    - assets/sounds/\n') if '    - assets/sounds/\n' not in s else s;p.write_text(s,encoding='utf8')
