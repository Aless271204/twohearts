"""Download this repository's build artifact without exposing credentials."""
import json,subprocess,urllib.request,urllib.parse,zipfile,hashlib,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
run_id=int(sys.argv[1]);name=sys.argv[2];destination=(ROOT/'outputs'/sys.argv[3]).resolve()
assert destination.is_relative_to((ROOT/'outputs').resolve())
c=subprocess.run(['git','credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True,check=True,timeout=30)
token=dict(line.split('=',1) for line in c.stdout.splitlines() if '=' in line)['password']
class SafeRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,req,fp,code,msg,headers,newurl):
  target=super().redirect_request(req,fp,code,msg,headers,newurl)
  if urllib.parse.urlparse(newurl).netloc!='api.github.com':target.remove_header('Authorization')
  return target
opener=urllib.request.build_opener(SafeRedirect())
def request(path):return urllib.request.Request('https://api.github.com/repos/Aless271204/twohearts/'+path,headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json'})
with opener.open(request(f'actions/runs/{run_id}/artifacts'),timeout=45) as response:artifacts=json.load(response)['artifacts']
artifact=next(a for a in artifacts if a['name']==name and not a['expired'])
print(json.dumps({'artifact':name,'archive_bytes':artifact['size_in_bytes']}),flush=True)
archive=ROOT/'outputs'/f'{run_id}-{name}.zip'
with opener.open(request(f'actions/artifacts/{artifact["id"]}/zip'),timeout=180) as response,archive.open('wb') as output:
 while chunk:=response.read(1024*1024):output.write(chunk)
destination.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(archive) as z:
 for entry in z.infolist():
  target=(destination/entry.filename).resolve()
  assert target.is_relative_to(destination),'Artifact escapes destination'
  z.extract(entry,destination)
report={'run':run_id,'artifact':name,'id':artifact['id'],'directory':str(destination),'files':len(list(destination.rglob('*'))),'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}
print(json.dumps(report))
