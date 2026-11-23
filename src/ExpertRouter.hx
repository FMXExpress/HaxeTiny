/** SPEC100 topic router ported from PasTinyMoE/PILOTRT.PAS (MIT).
    0 means original Tiny fallback, not a numbered specialist. No learned gate. */
class ExpertRouter {
 static final topicMap:Map<String,Int> = buildTopics();
 static function buildTopics():Map<String,Int> {var map=new Map<String,Int>();for(e in ExpertTopics.entries)map.set(e.term,e.id);return map;}
 static inline function has(text:String,term:String):Bool return text.indexOf(term)>=0;
 static function any(text:String,terms:Array<String>):Bool {for(t in terms)if(has(text,t))return true;return false;}
 static inline function member(n:Int,values:Array<Int>):Bool return values.indexOf(n)>=0;
 static inline function between(n:Int,a:Int,b:Int):Bool return n>=a&&n<=b;
 static function topic(word:String):Int return topicMap.exists(word)?topicMap.get(word):0;
 static function wordLine(q:String):String {var out=' ';for(i in 0...q.length){var c=q.charAt(i).toLowerCase();out+=~/^[a-z0-9]$/.match(c)?c:' ';}return out+' ';}
 static function synonym(c:String):Bool return any(c,[' synonym ',' synonyms ',' another word ',' alternative to ',' similar word ',' similar to ',' can replace ']);
 static function antonym(c:String):Bool return any(c,[' opposite ',' opposites ',' antonym ',' antonyms ',' reverse meaning ']);
 public static function rules(question:String):Int {
  var q=question.toLowerCase();var c=wordLine(q);var hits=0;var extra=ExpertGlossary.glossary(c);
  if(extra!=0)return extra;extra=ExpertGlossary.pcAndPascal(q,c);if(extra!=0)return extra;extra=ExpertGlossary.dosGlossary(q,c);if(extra!=0)return extra;
  var bbs=any(c,[' bbs ',' bulletin board ']);var frontier=any(c,[' frontier ',' frontiersman ',' cowpoke ']);var wordstar=has(c,' wordstar ');
  var file=any(c,[' dos ',' file ',' filename ',' directory ',' folder ']);var memory=any(c,[' conventional memory ',' base memory ',' upper memory ',' extended memory ',' expanded memory ',' high memory area ']);
  var onlyAncient=true;var mapContext=any(c,[' map ',' maps ']);var degrees=any(c,[' degree ',' degrees ']);
  var acoustic=any(c,[' acoustics ',' sound ',' tone ',' pitch ',' infrasound ',' ultrasound ']);
  var hasDos=false;var verbAffect=has(c,' how does ');var specificPascal=false;
  if(has(c,' read only memory '))hits=16;
  var i=0;
  while(i<q.length){
   var start=i;while(i<q.length&&~/^[a-z0-9]$/.match(q.charAt(i)))i++;
   if(i==start){i++;continue;}
   var w=q.substring(start,i);var matched=topic(w);
   if(verbAffect&&w=='affect')matched=0;
   if(w=='editor'||w=='editors')matched=0;
   if(w=='decimal'&&any(c,[' code ',' ascii ']))matched=0;
   if(matched==34&&!any(c,[' spreadsheet ',' formula ']))matched=0;
   if(w=='until'&&!has(c,' repeat '))matched=0;
   if(memberWord(w,['field','fields','bounds'])&&!any(c,[' record',' array',' pascal ']))matched=0;
   if(w=='typed'||w=='clause')matched=0;
   if(w=='interface'&&!any(c,[' interface section ',' unit ']))matched=0;
   if(w=='function'&&!any(c,[' function count ',' result ',' tp7 ',' pascal ']))matched=0;
   if(matched==14&&memberWord(w,['cell','cells'])&&!has(c,' text '))matched=0;
   if(w=='tab'&&has(c,' protect tab '))matched=0;
   if(w=='cr'||w=='lf')matched=10;
   if(memberWord(w,['scale','legend'])&&!mapContext)matched=0;
   if(degrees&&memberWord(w,['east','west']))matched=80;
   if(w=='river'&&has(c,' rome '))matched=0;
   if(matched==76&&extra==85)matched=extra;
   if(extra==76&&matched==85)extra=matched;
   if(w=='moon'&&has(c,' apollo '))matched=0;
   if(w=='atlantic'&&has(c,' lindbergh '))matched=0;
   if(w=='forge'&&has(c,' blacksmith '))matched=0;
   if(w=='verb'&&any(c,[' parser ',' adventure ']))matched=0;
   if(memberWord(w,['parent','root','extension'])&&!file)matched=0;
   if(w=='memory'&&!memory)matched=0;
   if(memberWord(w,['door','handle'])&&!bbs)matched=0;
   if(w=='echo'&&any(c,[' ate0 ',' ate1 ']))matched=0;
   if(frontier&&memberWord(w,['weather','traveler']))matched=0;
   if(acoustic&&memberWord(w,['hertz','frequency']))matched=68;
   if(matched==71&&!has(c,' capital '))matched=0;
   if(w=='wind'&&has(c,' does ')&&any(c,[' wind north ',' wind south ',' wind east ',' wind west ']))matched=0;
   if(matched==76&&w=='atlantic'&&has(c,' atlantic salmon '))matched=0;
   if(matched==73&&between(extra,74,76))matched=extra;
   if(extra==73&&between(matched,74,76))extra=matched;
   if(matched!=0){if(extra!=0&&extra!=matched)return 0;extra=matched;}
   var word='|'+w+'|';
   if(w=='file'&&wordstar)word='||';
   if(w=='block'&&(wordstar||any(c,[' marked block ',' mark block '])))word='||';
   if(has('|dos|dir|cd|cls|type|file|files|directory|directories|folder|folders|screen|display|',word)){hits|=1;if(word!='|type|')hasDos=true;}
   if(has('|pascal|div|mod|integer|quotient|remainder|divide|division|operator|compound|statement|block|',word)){hits|=2;if(word!='|statement|'&&word!='|compound|')specificPascal=true;}
   if(has('|animal|insect|insects|spider|spiders|',word))hits|=4;
   if(has('|brief|fragile|silent|rapid|vacant|damp|narrow|ancient|',word)&&!(w=='brief'&&start==3&&c.indexOf(' in brief ')==0)){hits|=8;if(w!='ancient')onlyAncient=false;}
   if(has('|ram|rom|cpu|processor|fpu|387|coprocessor|storage|disk|serial|parallel|workbench|',word))hits|=16;
  }
  if(antonym(c))return hits==8&&extra==0&&!synonym(c)?47:0;
  if((extra==78||between(extra,81,85))&&hits==8&&onlyAncient)hits=0;
  if(member(extra,[27,28,30,33,34,35,36])&&member(hits,[1,2,3]))hits=0;
  if(between(extra,17,20)&&member(hits,[1,16,17]))hits=0;
  if(between(extra,21,26)&&member(hits,[1,2,3]))hits=0;
  if(between(extra,7,16)&&member(hits,[1,16,17]))hits=0;
  if(extra==4&&hits==1)hits=0;
  if(extra==5){if(any(c,[' do i have ',' is installed ']))return 0;if(hits==1&&has(c,' dos '))hits=0;}
  if(extra==6&&hits==16&&has(c,' disk '))hits=0;
  if(extra==48&&!any(c,[' state ',' postal ',' address ',' abbreviation ']))return 0;
  if(between(extra,52,57)){if(any(c,[' how tall ',' how heavy ']))return 0;if(hits==1&&has(c,' type of ')&&!has(c,' dos '))hits=0;}
  if(extra==50&&hits==4&&has(c,' language '))hits=0;
  if(member(extra,[72,94,64])&&hits==1&&!hasDos)hits=0;
  if(extra==58&&hits==4)hits=0;
  if(between(extra,52,57)&&hits==4)hits=0;
  if(synonym(c))return hits==8&&extra==0?46:0;
  if(extra==45&&hits==2&&!specificPascal)hits=0;
  if(extra!=0)return hits==0?extra:0;
  return switch(hits){case 1:1;case 2:2;case 4:51;case 8:41;case 16:3;default:0;};
 }
 static inline function memberWord(word:String,values:Array<String>):Bool return values.indexOf(word)>=0;
 static function near(a:String,b:String):Bool {
  var la=a.length,lb=b.length;if(Std.int(Math.abs(la-lb))>1)return false;
  var i=0;while(i<la&&i<lb&&a.charAt(i)==b.charAt(i))i++;
  if(la==lb){if(i==la)return false;return a.substr(i+1)==b.substr(i+1)||(i+1<la&&a.charAt(i)==b.charAt(i+1)&&a.charAt(i+1)==b.charAt(i)&&a.substr(i+2)==b.substr(i+2));}
  return la>lb?a.substr(i+1)==b.substr(i):a.substr(i)==b.substr(i+1);
 }
 static function fixTypos(q:String):String {
  var out=new StringBuf();var i=0;
  while(i<q.length){var start=i;while(i<q.length&&~/^[a-zA-Z]$/.match(q.charAt(i)))i++;
   if(i==start){out.add(q.charAt(i++));continue;}
   var word=q.substring(start,i).toLowerCase();var found=0;var hit='';var clash=false;
   if(word.length>=6&&topic(word)==0)for(e in ExpertTopics.entries)if(e.term.charAt(0)==word.charAt(0)&&e.term.length>=7&&e.id!=42&&near(word,e.term)){if(found!=0&&found!=e.id)clash=true;found=e.id;hit=e.term;}
   out.add(hit!=''&&!clash?hit:word);
  }return out.toString();
 }
 public static function route(question:String):{id:Int,text:String,corrected:Bool} {
  var q=Model.clean(question);var id=rules(q);if(id!=0)return {id:id,text:q,corrected:false};
  var fixed=fixTypos(q);if(fixed!=q){id=rules(fixed);if(id!=0)return {id:id,text:fixed,corrected:true};}
  return {id:0,text:q,corrected:false};
 }
}
