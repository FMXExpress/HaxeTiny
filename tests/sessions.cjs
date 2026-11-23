// Exercise generated sidebar handlers with JSON-hydrated sessions and a minimal DOM.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
class Element {
 constructor(tag = 'div') {this.tagName = tag; this.children = []; this.options = [];  this.attrs = {}; this.style = {}; this.hidden = false; this.scrollHeight = 100; this._text = '';}
 set innerHTML(value) {this.children = []; this._text = value;}
 get innerHTML() {return this._text;}
 set textContent(value) {this._text = value; this.children = [];}
 get textContent() {return this._text || this.children.map(c => c.textContent).join('');}
 appendChild(child) {child.parentElement = this; this.children.push(child); return child;}
 setAttribute(name, value) {this.attrs[name] = value;}
 getAttribute(name) {return this.attrs[name] ?? null;}
 focus() {}
}
const ids = new Map();
const element = id => {if (!ids.has(id)) ids.set(id, new Element()); return ids.get(id);};
let stored;
const window = {document: {getElementById: element, createElement: tag => new Element(tag)},
 localStorage: {setItem(key, value) {stored = value;}}};
const sandbox = {window, console, Date, Math, setInterval, clearInterval, setTimeout, clearTimeout,
 HTMLTextAreaElement: Element, HTMLButtonElement: Element, HTMLInputElement: Element};
vm.createContext(sandbox);
const source = fs.readFileSync(path.join(__dirname, '../dist/app.js'), 'utf8');
vm.runInContext(source.replace('Main.main();', 'window.SessionTest = Main;'), sandbox);
const main = window.SessionTest;
// Real JSON parsing is essential: JSON arrays have slice(), but no Haxe-style copy().
main.sessions = JSON.parse(JSON.stringify([
 {title: 'First chat', turns: [{role:'user',text:'first question'},{role:'assistant',text:'first answer'}]},
 {title: 'Second chat', turns: [{role:'user',text:'second question'},{role:'assistant',text:'second answer'}]}
]));
main.renderHistory();
element('history').children[1].onclick({});
assert.equal(element('chatTitle').textContent, 'Second chat');
assert.equal(element('welcome').hidden, true);
assert.equal(element('messages').children.length, 2);
assert.equal(element('messages').children[1].textContent, 't.Tiny 2.1second answer');
assert.equal(main.current, 1);
assert.notEqual(main.turns, main.sessions[1].turns);
assert.equal(element('history').children[1].getAttribute('aria-current'), 'true');
// Switching again must load that button's own session, rather than a shared loop variable.
element('history').children[0].onclick({});
assert.equal(element('chatTitle').textContent, 'First chat');
assert.equal(main.turns[1].text, 'first answer');
// A new unsaved generation is saved by reset(), shifting all saved session indexes.
main.current = -1;
main.turns = [{role:'user',text:'new question'}];
main.busy = true;
main.answer = 'partial reply';
main.reply = main.add('assistant', main.answer);
let stopMessage;
main.worker = {postMessage(message) {stopMessage = message;}};
main.renderHistory();
element('history').children[1].onclick({});
assert.equal(stopMessage.type, 'stop');
assert.equal(main.busy, false);
assert.equal(main.sessions[0].title, 'new question');
assert.equal(main.current, 2);
assert.equal(element('chatTitle').textContent, 'Second chat');
assert.equal(main.turns[1].text, 'second answer');
assert.equal(element('messages').children.length, 2);
assert.equal(JSON.parse(stored)[0].turns[1].text, 'partial reply');
// Continuing a restored session must update it, preserving its previous messages.
main.turns.push({role:'user',text:'follow-up'},{role:'assistant',text:'next answer'});
main.save();
assert.equal(JSON.parse(stored)[2].turns.length, 4);
console.log('PASS: JSON session loading, separate sidebar handlers, active state, switching during generation, saved follow-ups');
