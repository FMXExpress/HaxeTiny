"""Package existing, verified Haxe outputs. Run from any directory after building all targets."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('version', help='Release tag, e.g. v0.1.0')
args = parser.parse_args()
if not args.version or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-' for c in args.version):
    parser.error('Use a version containing only letters, numbers, dots, and hyphens.')
out = ROOT / 'build/releases' / args.version
out.mkdir(parents=True, exist_ok=True)
staging = out / 'staging'
if staging.exists():
    shutil.rmtree(staging)
staging.mkdir()
commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
artifacts = []
for target in ['browser', 'python', 'php', 'linux-x86_64']:
    name = f'HaxeTiny-{args.version}-{target}'
    dest = staging / name
    dest.mkdir()
    for doc in ['README.md', 'LICENSE']:
        shutil.copy2(ROOT / doc, dest / doc)
    (dest / 'BUILD-INFO.json').write_text(json.dumps({
        'version': args.version, 'source_commit': commit, 'target': target,
        'compiler': 'Haxe 4.3.7', 'hxcpp': '4.3.2' if target == 'linux-x86_64' else None
    }, indent=2) + '\n')
    if target == 'browser':
        for filename in ['index.html', 'app.js', 'worker.js', 'style.css', 'TINY.BIN', 'source.zip']:
            shutil.copy2(ROOT / 'dist' / filename, dest / filename)
        instructions = 'Run: python3 -m http.server 8080\nOpen http://localhost:8080. Do not open index.html as a file.\nOr upload this directory to an HTTPS static web host. No Haxe installation required.\n'
    else:
        (dest / 'dist').mkdir()
        shutil.copy2(ROOT / 'dist/TINY.BIN', dest / 'dist/TINY.BIN')
        if target == 'python':
            shutil.copy2(ROOT / 'build/python/tiny.py', dest / 'tiny.py')
            instructions = 'Requires Python 3 (tested with 3.12); no third-party dependencies.\nRun: python3 tiny.py "what is 7 times 8"\n'
        elif target == 'php':
            shutil.copytree(ROOT / 'build/php', dest / 'php')
            instructions = 'Requires PHP CLI with mbstring enabled (tested with PHP 8.4).\nRun: php php/index.php "what is 7 times 8"\n'
        else:
            shutil.copy2(ROOT / 'build/cpp/CliMain', dest / 'tiny')
            (dest / 'tiny').chmod(0o755)
            instructions = 'Native Linux x86-64 executable, built on Debian 13 with hxcpp 4.3.2.\nRequires glibc >= 2.38 and libstdc++ providing GLIBCXX_3.4.21 / CXXABI_1.3.7.\nNot a Windows, macOS, ARM, musl/Alpine, or WebAssembly binary.\nRun: ./tiny "what is 7 times 8"\n'
        instructions += 'Run from this extracted directory so dist/TINY.BIN is found.\nOptions: --model PATH, --creativity 0-9, --help. Reads one question per line from stdin if no question is supplied.\nNo Haxe installation required to run.\n'
    (dest / 'RUNNING.txt').write_text(instructions)
    if target == 'linux-x86_64':
        archive = out / (name + '.tar.gz')
        with tarfile.open(archive, 'w:gz') as handle:
            handle.add(dest, arcname=name)
    else:
        archive = out / (name + '.zip')
        with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as handle:
            for path in sorted(dest.rglob('*')):
                if path.is_file():
                    handle.write(path, path.relative_to(staging))
    artifacts.append(archive)
(out / 'SHA256SUMS.txt').write_text(''.join(
    hashlib.sha256(path.read_bytes()).hexdigest() + '  ' + path.name + '\n'
    for path in artifacts))
print('\n'.join(str(path) for path in artifacts + [out / 'SHA256SUMS.txt']))
