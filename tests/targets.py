"""Run the same contract against any compiled CLI: python3 tests/targets.py <runner> [args...]."""
import pathlib
import struct
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
COMMAND = sys.argv[1:]
if not COMMAND:
    raise SystemExit('Usage: python3 tests/targets.py <runner> [args...]')

def run(*args, input=None):
    return subprocess.run(COMMAND + list(args), cwd=ROOT, input=input,
                          text=True, capture_output=True, timeout=180)

questions = ['what is the capital of peru', 'what is 7 times 8',
             'what is a baby kangaroo called', 'spell elephant',
             'what is the symbol for gold', 'WHAT IS 7 TIMES 8']
expected = ['Lima.', '7 times 8 is 56.', 'A joey.', 'E-L-E-P-H-A-N-T.',
            'It is Au.', '7 times 8 is 56.']
p = run(input='\n'.join(questions) + '\n')
assert p.returncode == 0, p.stderr
assert p.stdout.splitlines() == expected, p.stdout
assert run('--help').returncode == 0
assert run('--creativity', '10').returncode == 1
assert run('--model', 'missing-model.bin').returncode == 1
model = (ROOT / 'dist/TINY.BIN').read_bytes()
cases = [b'', b'NOPE' + model[4:], model[:12], model[:-1], model + b'x',
         model[:4] + struct.pack('<H', 0) + model[6:],
         model[:12] + struct.pack('<f', float('nan')) + model[16:]]
with tempfile.TemporaryDirectory() as tmp:
    for index, data in enumerate(cases):
        path = pathlib.Path(tmp) / f'invalid-{index}.bin'
        path.write_bytes(data)
        p = run('--model', str(path), 'hello')
        assert p.returncode == 1, (index, p.stdout, p.stderr)
        assert 'HaxeTiny:' in p.stderr, (index, p.stderr)
print('PASS: six reference answers, CLI options, and seven malformed models')
