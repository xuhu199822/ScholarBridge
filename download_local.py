"""Pinned official local inference dependencies. No system installation."""
import concurrent.futures
import hashlib
import pathlib
import urllib.request
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEST = ROOT / 'runtime'
ASSETS = [
    ('llama-b11617-bin-win-cpu-x64.zip',
     'https://github.com/ggml-org/llama.cpp/releases/download/b11617/llama-b11617-bin-win-cpu-x64.zip',
     '1bad07f7993889a1f7431ad647904294f56919bf0bc84f4021327db1641a411c'),
    ('Hy-MT2-1.8B-Q4_K_M.gguf',
     'https://huggingface.co/tencent/Hy-MT2-1.8B-GGUF/resolve/a0c709d9fac510f2c807aa3af52872340dc37a4a/Hy-MT2-1.8B-Q4_K_M.gguf',
     'dc5f44fcf1fa496ee7ad725982c0c8c553a4de00259b53af84c4b89fb0c06699'),
]

def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(4 * 1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()

def download(asset):
    name, url, sha = asset
    target = DEST / name
    if not target.exists() or digest(target) != sha:
        partial = target.with_suffix(target.suffix + '.partial')
        print('Downloading ' + name, flush=True)
        with urllib.request.urlopen(url, timeout=90) as response, partial.open('wb') as out:
            total = 0
            milestone = 0
            while True:
                chunk = response.read(4 * 1024 * 1024)
                if not chunk:
                    break
                out.write(chunk)
                total += len(chunk)
                if total // (100 * 1024 * 1024) > milestone:
                    milestone = total // (100 * 1024 * 1024)
                    print(name + ': ' + str(total // (1024 * 1024)) + ' MiB', flush=True)
        if digest(partial) != sha:
            raise RuntimeError('SHA-256 mismatch: ' + name)
        partial.replace(target)
    print('Verified ' + name, flush=True)
    if name.endswith('.zip'):
        folder = DEST / 'llama'
        folder.mkdir(exist_ok=True)
        with zipfile.ZipFile(target) as z:
            for member in z.infolist():
                candidate = (folder / member.filename).resolve()
                if not candidate.is_relative_to(folder.resolve()):
                    raise RuntimeError('Unsafe archive entry')
            z.extractall(folder)

if __name__ == '__main__':
    DEST.mkdir(exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        list(pool.map(download, ASSETS))
    print('Local model and runtime ready.', flush=True)
