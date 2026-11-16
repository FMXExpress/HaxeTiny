/** A small streaming CLI for PHP, Python, and C++. Paths are relative to the working directory. */
class CliMain {
 static function main() {
  try { run(); } catch(e:Dynamic) { Sys.stderr().writeString('HaxeTiny: '+Std.string(e)+'\n'); Sys.exit(1); }
 }
 static function run() {
  var args=Sys.args();
  if(args.indexOf('--help')>=0){Sys.println('Usage: <runner> [--model PATH] [--creativity 0-9] [QUESTION]\nWithout QUESTION, reads one question per line from stdin. Default model: dist/TINY.BIN');return;}
  var path='dist/TINY.BIN';var creativity=0;var words=[];var i=0;
  while(i<args.length){var arg=args[i++];switch(arg){
   case '--model':if(i>=args.length)throw '--model needs a path.';path=args[i++];
   case '--creativity':if(i>=args.length)throw '--creativity needs an integer from 0 to 9.';var value=args[i++];if(!~/^[0-9]$/.match(value))throw 'Creativity must be an integer from 0 to 9.';creativity=Std.parseInt(value);
   default: if(StringTools.startsWith(arg,'--'))throw 'Unknown option: '+arg;words.push(arg);
  }}
  var model=new Model(sys.io.File.getBytes(path));
  function answer(question:String){if(Model.clean(question).length==0)return;model.answer(question,creativity,function(letter){Sys.print(letter);});Sys.println('');}
  if(words.length>0){answer(words.join(' '));return;}
  while(true){var line:String;try{line=Sys.stdin().readLine();}catch(e:haxe.io.Eof){break;}answer(line);}
 }
}
