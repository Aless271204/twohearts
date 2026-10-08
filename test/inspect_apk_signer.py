"""Read public signer identities from the APK v2 block; never extracts private keys."""
import hashlib
import json
import struct
import sys
from pathlib import Path

def field(data, offset=0):
    size = struct.unpack_from('<I', data, offset)[0]
    end = offset + 4 + size
    if end > len(data):
        raise ValueError('Truncated signing field')
    return data[offset + 4:end], end

def signer(path):
    path = Path(path)
    with path.open('rb') as apk:
        apk.seek(-min(path.stat().st_size, 65557), 2)
        tail = apk.read()
        eocd = tail.rfind(b'PK\x05\x06')
        if eocd < 0:
            raise ValueError('Missing ZIP directory')
        central = struct.unpack_from('<I', tail, eocd + 16)[0]
        apk.seek(central - 24)
        footer = apk.read(24)
        if footer[8:] != b'APK Sig Block 42':
            raise ValueError('Missing APK signing block')
        size = struct.unpack_from('<Q', footer)[0]
        if size > 10_000_000:
            raise ValueError('Unexpected signing block size')
        apk.seek(central - size - 8)
        block = apk.read(size + 8)
    if struct.unpack_from('<Q', block)[0] != size:
        raise ValueError('Signing block sizes disagree')
    pos = 8
    while pos < len(block) - 24:
        length = struct.unpack_from('<Q', block, pos)[0]
        identifier = struct.unpack_from('<I', block, pos + 8)[0]
        value = block[pos + 12:pos + 8 + length]
        pos += 8 + length
        if identifier == 0x7109871a:
            signers, _ = field(value)
            first, _ = field(signers)
            signed, _ = field(first)
            _, offset = field(signed)
            certificates, _ = field(signed, offset)
            certificate, _ = field(certificates)
            return hashlib.sha256(certificate).hexdigest()
    raise ValueError('Missing APK v2 signer')

if __name__ == '__main__':
    print(json.dumps({str(Path(p).name): signer(p) for p in sys.argv[1:]}))
