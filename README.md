# HaxeTiny — Tiny 2.1 for modern browsers

A direct Haxe port of the inference engine in https://github.com/WollyMonjac/Tiny-2.1, with a responsive browser chat UI. No backend, API key, or JavaScript inference library. The application and worker compile from Haxe to JavaScript. The original TINY.BIN is bundled unchanged.

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

## Verification

`node tests/inference.cjs` checks the compiled worker against five exact answers captured from the upstream C executable with creativity zero. Browser UI testing was unavailable in the build environment.

## Behavior and limits

- Loads the bundled 380 KB model automatically; import another compatible TNY2 .bin through Model Inspector. Settings are accessible through the gear on small screens.
- Original dimensions supported: 8–128 wide, 1–8 layers, head count dividing width, middle width 8–512. Invalid headers, non-finite weights, truncation, and trailing bytes are rejected.
- Original row-scaled signed-byte matrices, RMS normalization, ReLU feedforward, tied embeddings, causal multi-head attention, quantized KV cache, and creativity sampling.
- JavaScript double precision accumulators and Float32 buffers can cause small numerical differences from C; deterministic sample answers match. Random answers need not match C's RNG.
- 72 printable ASCII characters per question; 128 total character positions. All-uppercase input becomes lowercase, as in the original. Each question resets context; visible history is not model memory.
- Stop cancels work between inference steps. Questions and up to 20 conversations are stored only in this browser's localStorage. No questions are sent to a server. Google Fonts is used for typography with system fallbacks.
- Tiny knows a limited training set of roughly 3,500 facts and can confidently produce wrong answers. This is not a modern general purpose LLM.

## Source

`src/Model.hx`: binary reader and transformer. `src/WorkerMain.hx`: worker protocol, character streaming and cancellation. `src/Main.hx`: UI and local chat history. `dist/`: deployable static application.

## Attribution

Based on WollyMonjac/Tiny-2.1 at commit 1d5cf54677addf188a090ca1c91acb3d02989a1d. Upstream credits Fable 5.2 for the C program and Opus 5.5 for training. TINY.BIN is the upstream model. The upstream repository did not contain an explicit license when inspected; no additional rights to the upstream code or weights are asserted by this port.

The repository’s existing MIT license is preserved for original contributions. Upstream material retains its own licensing status as described above.
