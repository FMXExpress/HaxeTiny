# HaxeTiny — Tiny 2.1 for modern browsers

A direct Haxe port of the inference engine in https://github.com/WollyMonjac/Tiny-2.1, with a responsive browser chat UI. No backend, API key, or JavaScript inference library. The browser application and worker compile from Haxe to JavaScript; the same model engine also compiles to PHP, Python, and native C++. The original TINY.BIN is bundled unchanged.

## Ready-to-run downloads

Get the compiled packages from [GitHub Releases](https://github.com/FMXExpress/HaxeTiny/releases). Each release has separate browser JavaScript, PHP, Python, and native Linux x86-64 downloads, each including the original model and `RUNNING.txt`. No Haxe installation is needed to run them. PHP needs PHP CLI with mbstring; Python needs Python 3.

The C++ download is a **native Linux x86-64 executable**, built on Debian 13. It requires glibc 2.38 or newer and libstdc++ with GLIBCXX_3.4.21 / CXXABI_1.3.7. Windows and macOS executables require builds on those platforms; WebAssembly is not configured. The browser download uses JavaScript.

To package a release after building and testing all four targets, run `python3 scripts/package-release.py v0.1.0`. Archives and SHA-256 checksums go into the ignored `build/releases/` directory. This packaging script currently expects the native build to be Linux x86-64.

## Build and run

Clone this repository and install Haxe 4.3.7 or newer, then:

```sh
git clone https://github.com/FMXExpress/HaxeTiny.git
cd HaxeTiny
haxe build.hxml
haxe worker.hxml
python3 -m http.server 8080 --directory dist
```

Open http://localhost:8080. Static hosting over HTTPS also works. Serve over HTTP rather than opening index.html as a file; browsers restrict worker and fetch access from file URLs. No haxelib dependencies. Generated JavaScript is checked in, so the dist directory runs without installing Haxe.

## PHP, Python, and C++

Run these commands from the repository root. Each runner loads `dist/TINY.BIN` by default, accepts a question as an argument, or reads one question per line from stdin. These targets provide a command-line interface and reusable model engine; the browser chat UI remains JavaScript-only.

```sh
# Python 3 (no third-party Python dependencies)
haxe python.hxml
python3 build/python/tiny.py "what is 7 times 8"

# PHP CLI with the mbstring extension enabled (tested on PHP 8.4)
haxe php.hxml
php build/php/index.php "what is 7 times 8"

# Native C++: install hxcpp and a supported C++ toolchain first
haxelib install hxcpp 4.3.2
haxe cpp.hxml
./build/cpp/CliMain "what is 7 times 8"
```

On Windows the native executable is `build/cpp/CliMain.exe`. hxcpp requires the platform toolchain (GCC on Linux, Xcode command-line tools on macOS, or supported Visual Studio C++ tools on Windows). The native build was verified on Linux.

All runners support `--model PATH`, `--creativity 0-9`, and `--help`. The CLI defaults to creativity **0** for reproducible answers; the browser defaults to **5**. For example:

```sh
python3 build/python/tiny.py --model dist/TINY.BIN --creativity 5 "tell me a joke"
printf 'what is 7 times 8\nspell elephant\n' | python3 build/python/tiny.py
```

For embedding on any supported target:

```haxe
var model = new Model(sys.io.File.getBytes("dist/TINY.BIN"));
var reply = model.answer("what is the capital of peru", 0);
```

The core accepts `haxe.io.Bytes`. In JavaScript, wrap an ArrayBuffer with `haxe.io.Bytes.ofData(buffer)`. JavaScript keeps native typed arrays; other targets use portable Float32 buffers and signed-byte storage. The PHP and Python versions prioritize portability and can be considerably slower than native C++ or JavaScript. Do not share a single Model instance concurrently between requests or threads: inference mutates its working buffers and KV cache.

## Verification

`node tests/inference.cjs` checks the compiled worker against five exact answers captured from the upstream C executable with creativity zero. Browser UI testing was unavailable in the build environment.

After compiling the CLI targets, run their shared inference, argument-validation, and malformed-model checks:

```sh
python3 tests/targets.py python3 build/python/tiny.py
python3 tests/targets.py php build/php/index.php
python3 tests/targets.py ./build/cpp/CliMain
```

Regenerate the in-app source download after source changes with `python3 scripts/package-source.py`.

## Behavior and limits

- Loads the bundled 380 KB model automatically; import another compatible TNY2 .bin through Model Inspector. Settings are accessible through the gear on small screens.
- Original dimensions supported: 8–128 wide, 1–8 layers, head count dividing width, middle width 8–512. Invalid headers, non-finite weights, truncation, and trailing bytes are rejected.
- Original row-scaled signed-byte matrices, RMS normalization, ReLU feedforward, tied embeddings, causal multi-head attention, quantized KV cache, and creativity sampling.
- JavaScript double precision accumulators and Float32 buffers can cause small numerical differences from C; deterministic sample answers match. Random answers need not match C's RNG.
- 72 printable ASCII characters per question; 128 total character positions. All-uppercase input becomes lowercase, as in the original. Each question resets context; visible history is not model memory.
- Stop cancels work between inference steps. Questions and up to 20 conversations are stored only in this browser's localStorage. No questions are sent to a server. Google Fonts is used for typography with system fallbacks.
- Tiny knows a limited training set of roughly 3,500 facts and can confidently produce wrong answers. This is not a modern general purpose LLM.

## Source

`src/Model.hx`: portable binary reader and transformer. `src/FloatBuffer.hx` and `src/ByteBuffer.hx`: target-specific storage. `src/CliMain.hx`: PHP/Python/C++ runner. `src/WorkerMain.hx`: worker protocol, character streaming and cancellation. `src/Main.hx`: UI and local chat history. `dist/`: deployable static application.

## Attribution

Based on WollyMonjac/Tiny-2.1 at commit 1d5cf54677addf188a090ca1c91acb3d02989a1d. Upstream credits Fable 5.2 for the C program and Opus 5.5 for training. TINY.BIN is the upstream model. The upstream repository did not contain an explicit license when inspected; no additional rights to the upstream code or weights are asserted by this port.

The repository’s existing MIT license is preserved for original contributions. Upstream material retains its own licensing status as described above.
