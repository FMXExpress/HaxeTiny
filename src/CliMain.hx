/** A small streaming CLI for PHP, Python, and C++. Paths are relative to the working directory. */
class CliMain {
 static function main() {
  try { run(); } catch(e:Dynamic) { Sys.stderr().writeString('HaxeTiny: '+Std.string(e)+'\n'); Sys.exit(1); }
 }
 static function run() {
  var args=Sys.args();
  if(args.indexOf('--help')>=0){Sys.println('Usage: <runner> [--model PATH] [--creativity 0-9] [--expert auto|general|ID] [--catalog PATH] [--list-experts] [--verbose] [QUESTION]\nWithout QUESTION, reads one question per line from stdin. Default model: dist/TINY.BIN');return;}
  var path='dist/TINY.BIN';var creativity=0;var words=[];var i=0;var catalogPath='dist/experts/catalog.json';var expertMode=false;var selection=0;var list=false;var verbose=false;
  while(i<args.length){var arg=args[i++];switch(arg){
   case '--catalog':if(i>=args.length)throw '--catalog needs a path.';catalogPath=args[i++];expertMode=true;
   case '--list-experts':list=true;expertMode=true;
   case '--verbose':verbose=true;
   case '--expert':
    if(i>=args.length)throw '--expert needs auto, general, or an expert ID.';
    var value=args[i++];expertMode=true;
    if(value=='auto')selection=-1;else if(value=='general')selection=0;else {if(!~/^[0-9]{1,3}$/.match(value))throw 'Invalid expert ID.';selection=Std.parseInt(value);if(selection<1||selection>128)throw 'Expert ID must be between 1 and 128.';}
   case '--model':if(i>=args.length)throw '--model needs a path.';path=args[i++];
   case '--creativity':if(i>=args.length)throw '--creativity needs an integer from 0 to 9.';var value=args[i++];if(!~/^[0-9]$/.match(value))throw 'Creativity must be an integer from 0 to 9.';creativity=Std.parseInt(value);
   default: if(StringTools.startsWith(arg,'--'))throw 'Unknown option: '+arg;words.push(arg);
  }}
  var model:Model=null;var experts:ExpertSet=null;
  if(expertMode){var catalog=new ExpertCatalog(sys.io.File.getContent(catalogPath));if(list){Sys.println('0\tOriginal Tiny');for(e in catalog.entries)Sys.println(e.id+'\t'+e.title);return;}if(selection>0)catalog.get(selection);experts=new ExpertSet(catalog,haxe.io.Path.directory(catalogPath),path,sys.io.File.getBytes);}
  else model=new Model(sys.io.File.getBytes(path));
  function answer(question:String){
   if(Model.clean(question).length==0)return;
   var input=question;
   if(experts!=null){var route=experts.select(question,selection);model=experts.model;input=route.text;if(verbose){Sys.stderr().writeString('Expert '+route.id+': '+route.title+'\n');if(route.corrected)Sys.stderr().writeString('Read as: '+route.text+'\n');}}
   model.answer(input,creativity,function(letter){Sys.print(letter);});Sys.println('');
  }
  if(words.length>0){answer(words.join(' '));return;}
  while(true){var line:String;try{line=Sys.stdin().readLine();}catch(e:haxe.io.Eof){break;}answer(line);}
 }
}
