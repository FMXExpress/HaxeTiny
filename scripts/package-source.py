"""Rebuild the browser's source download without build products or hosting state."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
files = ['README.md', 'LICENSE', '.gitignore', 'build.hxml', 'worker.hxml',
         'python.hxml', 'php.hxml', 'cpp.hxml', 'dist/index.html',
         'dist/style.css', 'dist/TINY.BIN', 'dist/app.js', 'dist/worker.js']
for directory in ['src', 'tests', 'scripts']:
    files.extend(str(p.relative_to(root)) for p in (root / directory).rglob('*')
                 if p.is_file() and '__pycache__' not in p.parts)
with ZipFile(root / 'dist/source.zip', 'w', ZIP_DEFLATED) as archive:
    for name in sorted(files):
        archive.write(root / name, 'HaxeTiny/' + name)
print('Updated dist/source.zip')
