class WorkerMain {
 static var scope:Dynamic=js.Syntax.code('self'); static var model:Model; static var serial=0;
 static function send(v:Dynamic) scope.postMessage(v);
 static function main(){scope.onmessage=function(e:Dynamic){var m=e.data;switch(m.type){
 case 'load': serial++; try {var next=new Model(haxe.io.Bytes.ofData(m.buffer));model=next;send({type:'ready',d:model.d,layers:model.layers,heads:model.heads,hidden:model.hidden});}catch(e:Dynamic)send({type:'error',message:Std.string(e)});
 case 'stop':serial++;
 case 'ask': if(model==null)return; var id=++serial;var text=Model.clean(m.text);var p=0;var out='';var started=Date.now().getTime();var creativity:Int=m.creativity;
 function tick(){if(id!=serial)return;try {if(p<text.length){model.step(text.charCodeAt(p)-30,p);p++;send({type:'reading',progress:p/text.length});haxe.Timer.delay(tick,0);return;}if(p==text.length){model.step(1,p++);haxe.Timer.delay(tick,0);return;}var tok=model.pick(creativity);if(tok<=1||p>=128){send({type:'done',text:out,ms:Date.now().getTime()-started});return;}out+=String.fromCharCode(tok+30);send({type:'token',text:out,confidence:model.confidence,activity:model.activity,ms:Date.now().getTime()-started});model.step(tok,p++);haxe.Timer.delay(tick,0);}catch(e:Dynamic)send({type:'error',message:Std.string(e)});}
 tick();
 }};}
}
