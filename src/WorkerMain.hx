import haxe.io.Bytes;
class WorkerMain {
 static var scope:Dynamic=js.Syntax.code('self');
 static var model:Model;static var serial=0;static var modelKey='';
 static var catalog:ExpertCatalog;static var catalogPromise:Dynamic;
 static function send(value:Dynamic)scope.postMessage(value);
 static function fetchBytes(url:String):Dynamic return scope.fetch(url).then(function(r:Dynamic){if(!r.ok)throw 'Download failed: '+url+' (HTTP '+r.status+')';return r.arrayBuffer();});
 static function getCatalog():Dynamic {
  if(catalogPromise==null)catalogPromise=scope.fetch('experts/catalog.json').then(function(r:Dynamic){if(!r.ok)throw 'Expert catalog unavailable.';return r.text();}).then(function(text:String){catalog=new ExpertCatalog(text);return catalog;});
  return catalogPromise;
 }
 static function catalogError(error:Dynamic){catalogPromise=null;send({type:'catalogError',message:Std.string(error)});}
 static function main(){scope.onmessage=function(e:Dynamic){var m=e.data;switch(m.type){
  case 'catalog':getCatalog().then(function(_:Dynamic){send({type:'catalog',entries:catalog.entries});return null;},function(error:Dynamic){catalogError(error);return null;});
  case 'load':serial++;try{var next=new Model(Bytes.ofData(m.buffer));model=next;modelKey=m.custom==true?'custom':'general';send({type:'ready',d:model.d,layers:model.layers,heads:model.heads,hidden:model.hidden});}catch(error:Dynamic)send({type:'error',message:Std.string(error)});
  case 'stop':serial++;
  case 'ask':ask(m);
 }};}
 static function ask(m:Dynamic){
  var id=++serial;var text=Model.clean(m.text);var requested:Int=m.expert==null?0:m.expert;
  var route=requested == -1?ExpertRouter.route(text):{id:requested,text:text,corrected:false};
  var title=route.id==0?(modelKey=='custom'&&requested==0?'Custom model':'Original Tiny'):('Expert '+route.id);
  var start=function(){
   if(id!=serial)return;
   send({type:'selected',id:route.id,title:title,corrected:route.corrected,text:route.text,d:model.d,layers:model.layers});
   generate(route.text,m.creativity,id);
  };
  var fail=function(error:Dynamic){if(id==serial)send({type:'error',message:'Could not load '+title+': '+Std.string(error)+'. Previous model retained; no answer was generated.'});};
  if(route.id==0){
   send({type:'route',id:0,title:title,corrected:false,text:text});
   if(model!=null&&(modelKey=='general'||(requested==0&&modelKey=='custom'))){start();return;}
   fetchBytes('TINY.BIN').then(function(buffer:Dynamic){if(id!=serial)return null;var next=new Model(Bytes.ofData(buffer));model=next;modelKey='general';start();return null;}).then(null,fail);
  }else{
   getCatalog().then(function(_:Dynamic){
    if(id!=serial)return null;
    var entry=catalog.get(route.id);title=entry.title;
    send({type:'route',id:route.id,title:title,corrected:route.corrected,text:route.text});
    if(model!=null&&modelKey==Std.string(route.id)){start();return null;}
    return fetchBytes('experts/'+entry.name).then(function(buffer:Dynamic){if(id!=serial)return null;var next=catalog.decode(route.id,Bytes.ofData(buffer));model=next;modelKey=Std.string(route.id);start();return null;});
   }).then(null,fail);
  }
 }
 static function generate(text:String,creativity:Int,id:Int){
  var p=0;var out='';var started=Date.now().getTime();
  function tick(){if(id!=serial)return;try{
   if(p<text.length){model.step(text.charCodeAt(p)-30,p);p++;send({type:'reading',progress:p/text.length});haxe.Timer.delay(tick,0);return;}
   if(p==text.length){model.step(1,p++);haxe.Timer.delay(tick,0);return;}
   var tok=model.pick(creativity);if(tok<=1||p>=128){send({type:'done',text:out,ms:Date.now().getTime()-started});return;}
   out+=String.fromCharCode(tok+30);send({type:'token',text:out,confidence:model.confidence,activity:model.activity,ms:Date.now().getTime()-started});model.step(tok,p++);haxe.Timer.delay(tick,0);
  }catch(error:Dynamic)send({type:'error',message:Std.string(error)});}
  tick();
 }
}
