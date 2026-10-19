"""Read a compact build snapshot; never print authentication material."""
import json,sys,urllib.request,urllib.parse
base='https://api.github.com/repos/Aless271204/twohearts/'
def get(path):
 with urllib.request.urlopen(urllib.request.Request(base+path,headers={'User-Agent':'NIDO-build-status','Accept':'application/vnd.github+json'}),timeout=40) as response:return json.load(response)
if len(sys.argv)>1:
 run=get('actions/runs/'+sys.argv[1])
else:
 runs=get('actions/workflows/forest-runner.yml/runs?branch=codex%2Fguardian-alba-prototype&per_page=1')['workflow_runs'];run=runs[0]
jobs=get('actions/runs/'+str(run['id'])+'/jobs')['jobs']
print(json.dumps(dict(run=run['id'],commit=run['head_sha'],status=run['status'],conclusion=run['conclusion'],jobs=[dict(id=j['id'],name=j['name'],status=j['status'],conclusion=j['conclusion'],active=[s['name'] for s in j.get('steps',[]) if s['status']=='in_progress']) for j in jobs])))
