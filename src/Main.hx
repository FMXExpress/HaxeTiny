import ExpertCatalog.ExpertEntry;
import js.Browser;
import js.html.Element;
import js.html.TextAreaElement;
import js.html.InputElement;
import js.html.ButtonElement;
import js.html.Worker;
private typedef ChatTurn = { var role:String; var text:String; @:optional var expert:String; }
private typedef ChatSession = { var title:String; var turns:Array<ChatTurn>; }
class Main {
 static var activeExpertTitle='Tiny 2.1';
 static var voice=new RobotVoice();static var voiceEnabled=false;static var speaking:Element;
 static var worker:Worker; static var ready=false;static var busy=false;static var reply:Element;static var answer='';static var turns:Array<ChatTurn>=[];static var sessions:Array<ChatSession>=[];static var current=-1;
 static function el(id:String):Element return Browser.document.getElementById(id);
 static function text(id:String,s:String) el(id).textContent=s;
 static function main(){
  voice.onStop=function(){el('voiceStop').hidden=true;text('voiceState','');if(speaking!=null){speaking.textContent=speaking.getAttribute('data-spoken-text');speaking=null;}};
  el('voiceToggle').onclick=function(_){
   if(!voiceEnabled&&!voice.unlock()){notice('Web Audio is unavailable in this browser.');return;}
   voiceEnabled=!voiceEnabled;if(!voiceEnabled)voice.stop();
   text('voiceToggle',voiceEnabled?'Robot voice: On':'Robot voice: Off');el('voiceToggle').setAttribute('aria-pressed',Std.string(voiceEnabled));
  };
  el('voiceTest').onclick=function(_){playVoice('Hello, I am Tiny. A little robot in your browser.');};
  el('voiceStop').onclick=function(_){voice.stop();};
  var volume:InputElement=cast el('voiceVolume');volume.oninput=function(_){voice.volume=Std.parseFloat(volume.value)/100;};
  Browser.document.addEventListener('keydown',function(_){if(voice.playing)voice.stop();});
  Browser.document.addEventListener('visibilitychange',function(_){if(Browser.document.hidden)voice.stop();});
  el('inspectorToggle').onclick=function(_){Browser.document.body.classList.toggle('show-inspector');};
  worker=new Worker('worker.js');worker.onmessage=function(e){var m:Dynamic=e.data;switch(m.type){
   case 'catalog':
    var select:js.html.SelectElement=cast el('expertMode');
    var selected=select.value;select.innerHTML='<option value="0">Original Tiny · general model</option><option value="-1">Auto · 100 specialists + Tiny fallback</option>';
    var entries:Array<ExpertEntry>=m.entries;
    for(entry in entries){var option=Browser.document.createOptionElement();option.value=Std.string(entry.id);option.textContent=StringTools.lpad(Std.string(entry.id),'0',3)+' · '+entry.title;select.appendChild(option);}
    select.value=selected;select.disabled=busy;text('expertStatus','100 specialists available · one active model at a time');
   case 'catalogError':text('expertStatus','Specialists unavailable; original Tiny still works.');
   case 'route':
    activeExpertTitle=m.title;text('expertStatus','Selecting '+m.title+(m.corrected?' · Read as: '+m.text:''));
    if(reply!=null)reply.textContent='Loading '+m.title+'…';
   case 'selected':
    activeExpertTitle=m.title;text('expertStatus',m.title+(m.corrected?' · Read as: '+m.text:''));text('modelTitle',m.title);text('arch',m.layers+' × '+m.d);text('size','373 KB');
    if(reply!=null){var label=reply.parentElement.querySelector('.message-label');if(label!=null)label.textContent=m.title;}
   case 'ready':ready=true;text('modelTitle','Tiny 2.1');text('status','Model ready');el('statusDot').className='ready';text('arch',m.layers+' × '+m.d);el('layers').innerHTML='';for(i in 0...Std.int(m.layers)){var row=Browser.document.createDivElement();row.className='layer';row.innerHTML='<span>L'+(i+1)+'</span><div class="track"><i id="layer'+i+'"></i></div>';el('layers').appendChild(row);}notice('');controls();
   case 'reading':text('activityState','READING');reply.textContent='Reading your question…';
   case 'token':answer=m.text;reply.textContent=answer;text('activityState','GENERATING');text('confidence',Math.round(m.confidence*100)+'%');el('confidenceBar').style.width=(m.confidence*100)+'%';var act:Array<Float>=m.activity;for(i in 0...act.length)el('layer'+i).style.width=(Math.min(100,act[i]*25))+'%';text('speed',Std.string(Math.round(answer.length/Math.max(1,m.ms)*10000)/10)+' char/s');scroll();
   case 'done':answer=m.text;finish(answer.length==0?'The model returned no text. Try rephrasing.':null);
   case 'error':notice(m.message);if(busy)finish('Generation failed.');else{text('status',ready?'Model ready':'Model unavailable');controls();}
  }};
  try{sessions=haxe.Json.parse(Browser.window.localStorage.getItem('tiny-sessions'));if(sessions==null)sessions=[];}catch(_:Dynamic){}renderHistory();
  el('form').onsubmit=function(e){e.preventDefault();ask();};var input:TextAreaElement=cast el('prompt');input.oninput=function(_){text('count',input.value.length+' / 72');};input.onkeydown=function(e){if(e.key=='Enter'&&!e.shiftKey){e.preventDefault();ask();}};
  el('stop').onclick=function(_){worker.postMessage({type:'stop'});finish('Stopped');};el('newChat').onclick=function(_){reset();};
  for(button in Browser.document.querySelectorAll('[data-prompt]')){var b:Element=cast button;b.onclick=function(_){input.value=b.getAttribute('data-prompt');text('count',input.value.length+' / 72');ask();};}
  var range:InputElement=cast el('creativity');range.oninput=function(_)text('creativityValue',range.value);
  var file:InputElement=cast el('modelFile');file.onchange=function(_){if(file.files.length==0)return;var f=file.files[0];if(f.size>2000000){notice('Choose a Tiny model smaller than 2 MB.');return;}beginLoad();var reader=new js.html.FileReader();reader.onload=function(_){cast(el('expertMode'),js.html.SelectElement).value='0';worker.postMessage({type:'load',buffer:reader.result,custom:true});text('size',Math.round(f.size/1024)+' KB');};reader.onerror=function(_){notice('Could not read this file.');restore();};reader.readAsArrayBuffer(f);};
  el('reload').onclick=function(_){cast(el('expertMode'),js.html.SelectElement).value='0';loadBundled();worker.postMessage({type:'catalog'});};loadBundled();worker.postMessage({type:'catalog'});
 }
 static function notice(s:String)text('notice',s);
 static function restore(){text('status',ready?'Model ready':'Model unavailable');controls();}
 static function beginLoad(){voice.stop();if(busy){worker.postMessage({type:'stop'});finish('Stopped for model loading');}text('status','Loading model');cast(el('send'),ButtonElement).disabled=true;}
 static function loadBundled(){beginLoad();Browser.window.fetch('TINY.BIN').then(function(r){if(!r.ok)throw 'Model download failed';return r.arrayBuffer();}).then(function(b){worker.postMessage({type:'load',buffer:b});text('size',Math.round(b.byteLength/1024)+' KB');return null;}).catchError(function(e){notice('Could not load TINY.BIN. Retry or load a local model.');restore();});}
 static function controls(){var selection:js.html.SelectElement=cast el('expertMode');if(selection.options.length>2)selection.disabled=busy;cast(el('send'),ButtonElement).disabled=!ready||busy;el('send').hidden=busy;el('stop').hidden=!busy;cast(el('modelFile'),InputElement).disabled=busy;cast(el('creativity'),InputElement).disabled=busy;}
 static function add(role:String,content:String,?expert:String):Element {var node=Browser.document.createDivElement();node.className='message '+role;var avatar=Browser.document.createDivElement();avatar.className='avatar';avatar.textContent=role=='user'?'Y':'t.';var body=Browser.document.createDivElement();var label=Browser.document.createDivElement();label.className='message-label';label.textContent=role=='user'?'You':(expert!=null?expert:'Tiny 2.1');var value=Browser.document.createDivElement();value.className='message-text';value.textContent=content;body.appendChild(label);body.appendChild(value);node.appendChild(avatar);node.appendChild(body);el('messages').appendChild(node);return value;}
 static function ask(){if(!ready||busy)return;voice.stop();if(voiceEnabled)voice.unlock();var input:TextAreaElement=cast el('prompt');var q=Model.clean(input.value);if(q.length==0){notice('Use a short question with printable English characters.');return;}notice('');el('welcome').hidden=true;if(turns.length==0)text('chatTitle',q);turns.push({role:'user',text:q});add('user',q);input.value='';text('count','0 / 72');reply=add('assistant','Thinking…');answer='';activeExpertTitle='Tiny 2.1';busy=true;controls();scroll();worker.postMessage({type:'ask',text:q,expert:Std.parseInt(cast(el('expertMode'),js.html.SelectElement).value),creativity:Std.parseInt(cast(el('creativity'),InputElement).value)});}
 static function finish(note:String){if(!busy)return;busy=false;reply.textContent=answer.length>0?answer:(note==null?'No answer generated.':note);if(note!=null&&answer.length>0){var n=Browser.document.createDivElement();n.className='message-label';n.textContent=note;reply.parentElement.appendChild(n);}turns.push({role:'assistant',text:reply.textContent,expert:activeExpertTitle});text('activityState','IDLE');controls();save();scroll();if(note==null&&answer.length>0&&voiceEnabled)playVoice(answer,reply);}
 static function save(){var item={title:turns[0].text,turns:turns};if(current<0){sessions.unshift(item);current=0;}else sessions[current]=item;if(sessions.length>20)sessions=sessions.slice(0,20);try{Browser.window.localStorage.setItem('tiny-sessions',haxe.Json.stringify(sessions));}catch(_:Dynamic){notice('History could not be saved on this device.');}renderHistory();}
 static function renderHistory(){
  el('history').innerHTML='';
  for(i in 0...sessions.length){
   var session=sessions[i];
   var b=Browser.document.createButtonElement();
   b.className='history-item'+(i==current?' active':'');
   if(i==current)b.setAttribute('aria-current','true');
   b.textContent='◌  '+session.title;
   b.onclick=function(_){
    // reset() can save an in-progress conversation and reorder the sidebar.
    reset();
    current=sessions.indexOf(session);
    turns=session.turns.copy();
    el('welcome').hidden=true;
    text('chatTitle',session.title);
    for(t in turns)add(t.role,t.text,t.expert);
    renderHistory();scroll();
   };
   el('history').appendChild(b);
  }
 }
 static function reset(){voice.stop();if(busy){worker.postMessage({type:'stop'});finish('Stopped');}turns=[];current=-1;el('messages').innerHTML='';el('welcome').hidden=false;text('chatTitle','New conversation');notice('');cast(el('prompt'),TextAreaElement).focus();}
 static function playVoice(content:String,?element:Element){
  voice.stop();
  if(!voice.unlock()){notice('Web Audio is unavailable in this browser.');return;}
  speaking=element;if(element!=null)element.setAttribute('data-spoken-text',content);
  var ok=voice.play(content,function(start,length){
   if(element==null)return;
   element.textContent='';element.appendChild(Browser.document.createTextNode(content.substr(0,start)));
   var highlight=Browser.document.createElement('mark');highlight.className='spoken-word';highlight.textContent=content.substr(start,length);element.appendChild(highlight);
   element.appendChild(Browser.document.createTextNode(content.substr(start+length)));
  });
  if(ok){el('voiceStop').hidden=false;text('voiceState','Robot chatter · press any key to stop');}
  else{voice.stop();notice('Audio could not start. Try Test voice again.');}
 }
 static function scroll(){el('conversation').scrollTop=el('conversation').scrollHeight;}
}
