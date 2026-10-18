"""Enable static public hosting for the public NIDO test build."""
import json,subprocess,urllib.request,urllib.error
c=subprocess.run(['git','credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True,check=True,timeout=30)
token=dict(line.split('=',1) for line in c.stdout.splitlines() if '=' in line)['password']
url='https://api.github.com/repos/Aless271204/twohearts/pages'
headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28','Content-Type':'application/json'}
try:
 with urllib.request.urlopen(urllib.request.Request(url,headers=headers),timeout=45) as response:state=json.load(response)
 assert state.get('build_type')=='workflow','An existing Pages site uses a different source; preserve it.'
except urllib.error.HTTPError as error:
 if error.code!=404:raise
 with urllib.request.urlopen(urllib.request.Request(url,data=json.dumps({'build_type':'workflow'}).encode(),headers=headers,method='POST'),timeout=45) as response:state=json.load(response)
print(json.dumps({'url':state.get('html_url'),'build_type':state.get('build_type'),'status':state.get('status')}))
