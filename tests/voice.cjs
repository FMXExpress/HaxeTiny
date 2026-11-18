// Tests the Haxe-generated audio scheduler with a fake Web Audio clock; no browser/audio output.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
let serial = 0;
const timers = new Map();
let context;
class AudioContext {
  constructor() { context = this; this.state = 'running'; this.currentTime = 0; this.destination = {}; this.nodes = []; }
  resume() { return Promise.resolve(); }
  createGain() { return {gain: {value: 0}, connect() {}}; }
  createOscillator() {
    const node = {events: [], frequency: {setValueAtTime(hz, at) {node.events.push({hz, at});}},
      connect() {}, disconnect() {this.disconnected = true;},
      start(at) {this.startAt = at;}, stop(at) {this.stopAt = at;}};
    this.nodes.push(node); return node;
  }
}
const sandbox = {window: {AudioContext}, console, Date, Math, Promise,
  setInterval(fn, ms) {const id = ++serial; timers.set(id, {fn, ms}); return id;},
  clearInterval(id) {timers.delete(id);}, setTimeout, clearTimeout};
vm.createContext(sandbox);
const source = fs.readFileSync(path.join(__dirname, '../dist/app.js'), 'utf8');
assert(source.includes('Main.main();'));
vm.runInContext(source.replace('Main.main();', 'window.RobotVoiceTest = RobotVoice;'), sandbox);
const voice = new sandbox.window.RobotVoiceTest();
let stopped = 0;
voice.onStop = () => stopped++;
assert.equal(voice.play('a s p 7.'), true);
assert.equal(voice.playing, true);
assert.equal(context.nodes.length, 4);
const [vowel, hiss, click, digit] = context.nodes;
assert.equal(vowel.type, 'square');
assert(Math.abs(vowel.stopAt - vowel.startAt - 0.064) < 1e-9);
assert.equal(vowel.events[0].hz, Math.trunc(730 * 1.15));
assert.equal(vowel.events[1].hz, Math.trunc(1090 * 1.15));
assert.equal(vowel.events.length, 32);
assert.equal(hiss.events.length, 46);
assert(hiss.events.every(e => e.hz >= 2500 && e.hz <= 6999));
assert.equal(click.events[0].hz, 3200);
assert(Math.abs(click.stopAt - click.startAt - 0.002) < 1e-9);
assert(Math.abs(digit.startAt - click.startAt - 0.065) < 1e-9);
voice.set_volume(1); assert.equal(voice.volume, 0.2);
voice.set_volume(-1); assert.equal(voice.volume, 0);
voice.stop();
assert.equal(voice.playing, false);
assert.equal(stopped, 1);
assert.equal(timers.size, 0);
assert(context.nodes.every(n => n.disconnected));
let word;
voice.play('hi tiny', (start, length) => word = [start, length]);
const firstWord = [...timers.values()].sort((a,b) => a.ms-b.ms)[0];
firstWord.fn(); assert.deepEqual(word, [0, 2]);
voice.stop();
// Stop while resume() is pending; a late resolution must not begin playback.
context.state = 'suspended';
let resolveResume;
context.resume = () => new Promise(resolve => resolveResume = resolve);
voice.play('hello');
assert.equal(voice.playing, true);
voice.stop();
const count = context.nodes.length;
context.state = 'running';
resolveResume();
Promise.resolve().then(() => {
  assert.equal(context.nodes.length, count);
  assert.equal(timers.size, 0);
  sandbox.window.AudioContext = null;
  assert.equal(new sandbox.window.RobotVoiceTest().play('hello'), false);
  console.log('PASS: vowel/hiss/click scheduling, pauses, highlighting, volume bounds, stop, pending resume cancellation, unsupported audio');
}).catch(e => {console.error(e); process.exitCode = 1;});
