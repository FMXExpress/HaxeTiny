import haxe.io.Bytes;
typedef ExpertEntry = {var id:Int;var name:String;var title:String;var keyword:String;var sha256:String;}
class ExpertCatalog {
 public final entries:Array<ExpertEntry>;
 public function new(json:String){
  var value:Dynamic=haxe.Json.parse(json);if(value.version!=1||!Std.isOfType(value.experts,Array))throw 'Invalid expert catalog.';
  var list:Array<Dynamic>=value.experts;if(list.length<1||list.length>128)throw 'Invalid expert count.';
  entries=[];var ids=new Map<Int,Bool>();
  for(item in list){
   if(!Std.isOfType(item.id,Int)||item.id<1||item.id>128||ids.exists(item.id)||!Std.isOfType(item.name,String)||!~/^[A-Z0-9_]+\.BIN$/.match(item.name)||!Std.isOfType(item.title,String)||item.title.length>80||!Std.isOfType(item.sha256,String)||!~/^[a-f0-9]{64}$/.match(item.sha256))throw 'Invalid expert entry.';
   ids.set(item.id,true);entries.push(cast item);
  }
 }
 public function get(id:Int):ExpertEntry {for(e in entries)if(e.id==id)return e;throw 'Unknown expert: '+id;}
 public function decode(id:Int,bytes:Bytes):Model {
  var entry=get(id);if(haxe.crypto.Sha256.make(bytes).toHex()!=entry.sha256)throw 'Expert model checksum mismatch: '+entry.title;
  return new Model(bytes);
 }
}
