"""Run only after approval: private signing backup + encrypted GitHub secrets.
Requires cryptography and PyNaCl. Never prints credentials or private key data.
"""
import base64,ctypes,datetime,json,os,secrets,subprocess,sys,urllib.request
from pathlib import Path
from ctypes import wintypes
sys.path.insert(0,str(Path('.tools/signing-deps').resolve()))
from nacl.public import PublicKey,SealedBox
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes,serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs12

class Blob(ctypes.Structure):
    _fields_=[('size',wintypes.DWORD),('data',ctypes.POINTER(ctypes.c_ubyte))]

def dpapi(data, decrypt=False):
    buffer=(ctypes.c_ubyte*len(data)).from_buffer_copy(data)
    source=Blob(len(data),buffer);result=Blob()
    api=ctypes.windll.crypt32.CryptUnprotectData if decrypt else ctypes.windll.crypt32.CryptProtectData
    if not api(ctypes.byref(source),None,None,None,None,1,ctypes.byref(result)):
        raise ctypes.WinError()
    try: return ctypes.string_at(result.data,result.size)
    finally: ctypes.windll.kernel32.LocalFree(result.data)

def main():
    if os.name!='nt':raise RuntimeError('This backup uses Windows user encryption')
    folder=Path('outputs/signing');folder.mkdir(parents=True,exist_ok=True)
    account=os.environ['USERDOMAIN']+'\\'+os.environ['USERNAME']
    subprocess.run(['icacls',str(folder),'/inheritance:r','/grant:r',account+':(OI)(CI)F','SYSTEM:(OI)(CI)F'],check=True,capture_output=True)
    private=folder/'nido-upload.p12';protected=folder/'credentials.dpapi'
    if private.exists():password=json.loads(dpapi(protected.read_bytes(),True))['password']
    else:
        password=secrets.token_urlsafe(48);key=rsa.generate_private_key(public_exponent=65537,key_size=3072)
        subject=x509.Name([x509.NameAttribute(NameOID.COMMON_NAME,'NIDO App Upload')]);now=datetime.datetime.now(datetime.timezone.utc)
        cert=x509.CertificateBuilder().subject_name(subject).issuer_name(subject).public_key(key.public_key()).serial_number(x509.random_serial_number()).not_valid_before(now-datetime.timedelta(days=1)).not_valid_after(now+datetime.timedelta(days=10000)).sign(key,hashes.SHA256())
        private.write_bytes(pkcs12.serialize_key_and_certificates(b'nido-upload',key,cert,None,serialization.BestAvailableEncryption(password.encode())))
        protected.write_bytes(dpapi(json.dumps({'password':password,'alias':'nido-upload'}).encode()))
        (folder/'certificate.pem').write_bytes(cert.public_bytes(serialization.Encoding.PEM))
    credentials=subprocess.run(['git','credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True,check=True,timeout=30)
    fields=dict(line.split('=',1) for line in credentials.stdout.splitlines() if '=' in line);token=fields['password']
    endpoint='https://api.github.com/repos/Aless271204/twohearts/actions/secrets'
    def request(path,method='GET',body=None):
        req=urllib.request.Request(endpoint+path,data=json.dumps(body).encode() if body else None,method=method,headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28','Content-Type':'application/json'})
        with urllib.request.urlopen(req,timeout=30) as response:return json.loads(response.read() or b'{}')
    public=request('/public-key');box=SealedBox(PublicKey(base64.b64decode(public['key'])))
    values={'NIDO_KEYSTORE_BASE64':base64.b64encode(private.read_bytes()).decode(),'NIDO_STORE_PASSWORD':password,'NIDO_KEY_PASSWORD':password,'NIDO_KEY_ALIAS':'nido-upload'}
    for name,value in values.items():
        encrypted=base64.b64encode(box.encrypt(value.encode())).decode()
        request('/'+name,'PUT',{'encrypted_value':encrypted,'key_id':public['key_id']})
    print('Signing key backed up encrypted; four GitHub secrets configured. No private values printed.')

if __name__=='__main__':main()
