import haxe.io.Bytes;
/** One resident model, with injected synchronous IO for CLI or game embedding. */
class ExpertSet {
 public final catalog:ExpertCatalog;
 public var model(default,null):Model;
 var load:String->Bytes;var directory:String;var fallback:String;var loadedId=-1;
 public function new(catalog:ExpertCatalog,directory:String,fallback:String,load:String->Bytes){this.catalog=catalog;this.directory=directory;this.fallback=fallback;this.load=load;}
 public function select(question:String,selection:Int=-1):{id:Int,title:String,text:String,corrected:Bool} {
  var route=selection == -1?ExpertRouter.route(question):{id:selection,text:Model.clean(question),corrected:false};
  var title='Original Tiny';var path=fallback;
  if(route.id!=0){var entry=catalog.get(route.id);title=entry.title;path=directory+'/'+entry.name;}
  if(model==null||loadedId!=route.id){var bytes=load(path);var next=route.id==0?new Model(bytes):catalog.decode(route.id,bytes);model=next;loadedId=route.id;}
  return {id:route.id,title:title,text:route.text,corrected:route.corrected};
 }
}
