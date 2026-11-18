import js.Browser;

/** PC-speaker-style chatter based on TINY.C; no speech API or recorded audio. */
class RobotVoice {
 public var playing(default,null)=false;
 public var volume(default,set):Float=0.08;
 public var onStop:Void->Void=function() {};
 var context:Dynamic;
 var master:Dynamic;
 var nodes:Array<Dynamic>=[];
 var timers:Array<haxe.Timer>=[];
 var revision=0;

 public function new() {}
 function set_volume(value:Float):Float {
  volume=Math.max(0,Math.min(0.2,value));
  if(master!=null)master.gain.value=volume;
  return volume;
 }
 /** Call from a click/keypress, so autoplay policies permit the subsequent answer. */
 public function unlock():Bool {
  try {
   if(context==null){
    var constructor:Dynamic=js.Syntax.code('window.AudioContext || window.webkitAudioContext');
    if(constructor==null)return false;
    context=js.Syntax.code('new {0}()',constructor);
    master=context.createGain();master.gain.value=volume;master.connect(context.destination);
   }
   if(context.state=='suspended')js.Syntax.code('{0}.resume().catch(function() {})',context);
   return context.state!='closed';
  }catch(_:Dynamic){return false;}
 }
 public function stop() {
  revision++;
  for(timer in timers)timer.stop();timers=[];
  for(node in nodes){try{node.stop();}catch(_:Dynamic){} try{node.disconnect();}catch(_:Dynamic){}}
  nodes=[];
  var wasPlaying=playing;playing=false;
  if(wasPlaying)onStop();
 }
 public function play(text:String,?onWord:Int->Int->Void):Bool {
  stop();
  if(!unlock())return false;
  playing=true;
  var id=revision;
  // resume() may complete asynchronously; avoid scheduling into a suspended clock.
  var start=function(){if(id!=revision)return;try{schedule(text,onWord,id);}catch(_:Dynamic){stop();}};
  if(context.state=='running')start();
  else context.resume().then(function(_:Dynamic){start();return null;},function(_:Dynamic){stop();return null;});
  return true;
 }
 function schedule(text:String,onWord:Int->Int->Void,id:Int) {
  playing=true;
  var start:Float=context.currentTime+0.03;
  var offset=0.;var wordStart=0;
  for(i in 0...text.length){
   var c=text.charAt(i).toLowerCase();
   if(c!=' '&&(i==0||text.charAt(i-1)==' ')){
    wordStart=i;var end=i;while(end<text.length&&text.charAt(end)!=' ')end++;
    if(onWord!=null){var at=i;var length=end-i;later(function(){if(id==revision)onWord(at,length);},offset+0.03);}
   }
   var shift=(115-Std.int(30*wordStart/(text.length+1)))/100;
   switch(c){
    case 'a':buzz(730,1090,64,shift,start+offset);offset+=0.064;
    case 'e':buzz(530,1840,56,shift,start+offset);offset+=0.056;
    case 'i','y':buzz(300,2290,52,shift,start+offset);offset+=0.052;
    case 'o':buzz(570,840,64,shift,start+offset);offset+=0.064;
    case 'u':buzz(320,870,56,shift,start+offset);offset+=0.056;
    case 's','z','c','x':hiss(46,start+offset);offset+=0.046;
    case 'f','h','v','j':hiss(30,start+offset);offset+=0.030;
    case 'p','t','k','q':tone(3200,2,start+offset);offset+=0.020;
    case 'b','d','g':buzz(180,260,12,shift,start+offset);offset+=0.022;
    case 'm','n':buzz(210,300,40,shift,start+offset);offset+=0.040;
    case 'l','r','w':buzz(400,1100,36,shift,start+offset);offset+=0.036;
    case ' ':offset+=0.045;
    case ',','-':offset+=0.110;
    case '.','!','?',':':offset+=0.200;
    default:
     var digit=c.charCodeAt(0)-48;
     if(digit>=0&&digit<=9){buzz(420+digit*60,900+digit*90,70,shift,start+offset);offset+=0.072;}else offset+=0.020;
   }
  }
  later(function(){if(id==revision)stop();},offset+0.05);
 }
 function later(callback:Void->Void,seconds:Float){timers.push(haxe.Timer.delay(callback,Std.int(seconds*1000)));}
 function oscillator(at:Float,ms:Int):Dynamic {
  var node:Dynamic=context.createOscillator();node.type='square';node.connect(master);
  node.start(at);node.stop(at+ms/1000);nodes.push(node);return node;
 }
 function buzz(f1:Int,f2:Int,ms:Int,shift:Float,at:Float){
  var duration=Std.int(Math.ceil(ms/4))*4;
  var node=oscillator(at,duration);
  var t=0;while(t<duration){node.frequency.setValueAtTime(Std.int(f1*shift),at+t/1000);node.frequency.setValueAtTime(Std.int(f2*shift),at+(t+2)/1000);t+=4;}
 }
 function hiss(ms:Int,at:Float){var node=oscillator(at,ms);for(t in 0...ms)node.frequency.setValueAtTime(2500+Std.random(4500),at+t/1000);}
 function tone(hz:Int,ms:Int,at:Float){var node=oscillator(at,ms);node.frequency.setValueAtTime(hz,at);}
}
