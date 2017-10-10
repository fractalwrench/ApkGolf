#!/usr/bin/python3

import subprocess
import zipfile
import tempfile
import os

def zopfli_compress(data):
    with tempfile.NamedTemporaryFile() as outf:
        outf.write(data)
        outf.flush()
        result = subprocess.check_output(['zopfli', '--deflate', '-c', '--i1000', outf.name])
    return result

class ZopfliCompressor:
    def __init__(self):
        self.data = bytearray()

    def compress(self, data):
        self.data += data
        return b''

    def flush(self):
        return zopfli_compress(self.data)


orig_get_compressor = zipfile._get_compressor

def get_compressor(compress_type):
    if compress_type == zipfile.ZIP_DEFLATED:
        return ZopfliCompressor()
    else:
        return orig_get_compressor(compress_type)

zipfile._get_compressor = get_compressor

def main(argv):
    import argparse

    description = 'Create the tiniest zipfiles possible.'
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('zipfile')
    parser.add_argument('files', nargs='+')
    args = parser.parse_args(argv)

    zip_name = args.zipfile
    files = args.files

    def addToZip(zf, path, zippath):
        if os.path.isfile(path):
            # XXX this compresses things twice :(
            with open(path, 'rb') as inf:
                infdata = inf.read()
            if len(infdata) < len(zopfli_compress(infdata)):
                zf.write(path, zippath, zipfile.ZIP_STORED)
            else:
                zf.write(path, zippath, zipfile.ZIP_DEFLATED)
        elif os.path.isdir(path):
            if zippath:
                zf.write(path, zippath)
            for nm in os.listdir(path):
                addToZip(zf,
                         os.path.join(path, nm), os.path.join(zippath, nm))

    with zipfile.ZipFile(zip_name, 'w') as zf:
        for path in files:
            zippath = os.path.basename(path)
            if not zippath:
                zippath = os.path.basename(os.path.dirname(path))
            if zippath in ('', os.curdir, os.pardir):
                zippath = ''
            addToZip(zf, path, zippath)

if __name__ == "__main__":
    import sys
    main(sys.argv[1:])