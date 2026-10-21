"""Permit publishing only the reviewed native scene; unrelated later changes reuse it."""
import hashlib,json,os,time,urllib.request
from pathlib import Path
receipt=json.loads(Path('design/farolitos-lantern-garden/publish-review.json').read_text())
for file,expected in receipt['sources_sha256'].items():
 assert hashlib.sha256(Path(file).read_bytes().replace(b'\r\n',b'\n')).hexdigest()==expected,'Native scene review needs updating: '+file
repo=os.environ['GITHUB_REPOSITORY'];token=os.environ['GH_TOKEN']
def get(path):
 req=urllib.request.Request('https://api.github.com/repos/'+repo+'/'+path+'?fresh='+str(time.time_ns()),headers={'Authorization':'Bearer '+token,'User-Agent':'NIDO-review-gate','Accept':'application/vnd.github+json'})
 with urllib.request.urlopen(req,timeout=30)as response:return json.load(response)
for attempt in range(120):
 run=get('actions/runs/'+str(receipt['native_run_id']));statuses=get('commits/'+receipt['review_commit']+'/statuses');review=next((s for s in statuses if s['context']==receipt['status_context']),None)
 if run['status']=='completed' and run['conclusion']!='success':raise RuntimeError('Native scene verification failed')
 if review and review['state'] in ['failure','error']:raise RuntimeError('Native visual review requested corrections')
 if run['conclusion']=='success' and review and review['state']=='success':print('Native scene and visual review passed.');break
 if attempt%6==0:print('Waiting for native scene and visual review...',flush=True)
 time.sleep(10)
else:raise RuntimeError('Native visual review has not completed; publication remains blocked')
