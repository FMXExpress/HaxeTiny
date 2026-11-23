// Generated SPEC100 glossary precedence rules; PasTiny commit 7277199b701733cb8b2630f832b34d17d52c24b0.
class ExpertGlossary {
 static inline function pos(term:String,text:String):Int return text.indexOf(term)+1;
 public static function glossary(c:String):Int {
  if ((pos(' type mismatch ',c)>0) || (pos(' unknown identifier ',c)>0) ||
  (pos(' duplicate identifier ',c)>0) || (pos(' semicolon expected ',c)>0)) return 27;
  if ((pos(' single step ',c)>0) || (pos(' call stack ',c)>0) ||
  ((pos(' watch ',c)>0) && ((pos(' debug',c)>0) || (pos(' expression ',c)>0) ||
  (pos(' pascal ',c)>0) || (pos(' variable ',c)>0)))) return 28;
  if ((pos(' number notation ',c)>0) || (pos(' digits zero ',c)>0) ||
  (pos(' positional weight ',c)>0) || (pos(' place value ',c)>0) || (pos(' digit ',c)>0) &&
  ((pos(' weight ',c)>0) || (pos(' numeral ',c)>0)) ||
  ((pos(' base ',c)>0) && ((pos(' digits ',c)>0) || (pos(' hex ',c)>0) ||
  (pos(' zero and one ',c)>0)))) return 29;
  if ((pos(' boolean operator ',c)>0) || (pos(' logic gate ',c)>0) ||
  (pos(' logic circuit ',c)>0) || (pos(' truth table ',c)>0) || (pos(' boolean logic ',c)>0) || (pos(' boolean and ',c)>0) ||
  (pos(' boolean or ',c)>0) || (pos(' boolean not ',c)>0) || (pos(' boolean xor ',c)>0)
  || (pos(' and gate ',c)>0) || (pos(' or gate ',c)>0) || (pos(' not gate ',c)>0) ||
  (pos(' truth condition ',c)>0)) return 30;
  if ((pos(' sorting ',c)>0)) return 31;
  if ((pos(' structure ',c)>0) && ((pos(' record ',c)>0) || (pos(' node ',c)>0))) return 32;
  if ((pos(' zip ',c)>0) || (pos(' arc ',c)>0) || (pos(' lzh ',c)>0)) return 33;
  if (((pos(' spreadsheet ',c)>0) || (pos(' formula ',c)>0)) &&
  ((pos(' reference ',c)>0) || (pos(' copied ',c)>0) || (pos(' copy ',c)>0))) return 34;
  if ((pos(' database ',c)>0)) return 35;
  if ((pos(' editor ',c)>0) && ((pos(' caret ',c)>0) || (pos(' wrap',c)>0) ||
  (pos(' insert ',c)>0) || (pos(' overtype ',c)>0) || (pos(' block ',c)>0) ||
  (pos(' selection ',c)>0))) return 36;
  return 0;
 }
 public static function pcAndPascal(q:String,c:String):Int {
  if ((pos(' pc speaker ',c)>0) || ((pos(' simple tones ',c)>0) && (pos(' pc ',c)>0))) return 18;
  if ((pos(' symbols per second ',c)>0) || (pos(' symbols sent each second ',c)>0) ||
  ((pos(' stop bit ',c)>0) || (pos(' stop bits ',c)>0)) || (pos(' flow control ',c)>0) || (pos(' flow regulation ',c)>0) ||
  (pos(' asynchronous serial ',c)>0) || (pos(' serial sender ',c)>0)) return 19;
  if ((pos(' pc bus ',c)>0) || (pos(' expansion bus ',c)>0) || (pos(' local bus ',c)>0)
  || (pos(' standard architecture ',c)>0) || (pos(' micro channel ',c)>0)
  || (pos(' peripheral component interconnect ',c)>0) || (pos(' at expansion ',c)>0)
  || ((pos(' bus ',c)>0) && (pos(' 16 bits ',c)>0))) return 20;
  if ((pos(' typed file ',c)>0) || ((pos(' untyped ',c)>0) && (pos(' file ',c)>0)) ||
  (((pos(' pascal ',c)>0) || (pos(' tp7 ',c)>0)) && ((pos(' text file ',c)>0)
  || (pos(' text stream ',c)>0)))) return 25;
  if ((pos(' var ',c)>0) && (pos(':',q)>0) &&
  (pos(' function ',c)==0) && (pos(' procedure ',c)==0) && ((pos(' char ',c)>0) ||
  (pos(' byte ',c)>0) || (pos(' integer ',c)>0) || (pos(' boolean ',c)>0)
  || (pos(' longint ',c)>0))) return 21;
  if ((pos(';',q)>0) && (((pos(' if ',c)>0) && (pos(' then ',c)>0)) ||
  ((pos(' case ',c)>0) && (pos(' of ',c)>0)) || ((pos(' while ',c)>0) &&
  (pos(' do ',c)>0)) || ((pos(' for ',c)>0) && (pos(' do ',c)>0)) ||
  ((pos(' repeat ',c)>0) && (pos(' until ',c)>0)))) return 22;
  if ((pos(' uses clause ',c)>0) || (pos(' uses list ',c)>0) ||
  (pos(' uses keyword ',c)>0)) return 26;
  return 0;
 }
 public static function dosGlossary(q:String,c:String):Int {
  if ((pos(' config sys ',c)>0) || (pos(' autoexec bat ',c)>0) ||
    (pos(' command com ',c)>0)) return 8;
  if ((pos(' mda ',c)>0) || (pos(' cga ',c)>0) ||
    (pos(' ega ',c)>0) || (pos(' vga ',c)>0)) return 13;
  if ((pos(' root directory ',c)>0) &&
    ((pos(' fat ',c)>0) || (pos(' fat12 ',c)>0) || (pos(' fat16 ',c)>0))) return 7;
  if ((pos(' lock key ',c)>0) && (pos(' keyboard ',c)>0)) return 11;
  if ((pos(' bios cursor ',c)>0)) return 14;
  if ((pos(' dos text ',c)>0) && (pos(' pages ',c)==0) &&
    (pos(' mode ',c)==0)) return 10;
  if ((pos(' carriage return ',c)>0) || (pos(' line feed ',c)>0) ||
    (pos(' horizontal tab ',c)>0) || (pos(' ctrl z ',c)>0) ||
    (pos(' file length ',c)>0) || (pos(' disk file ',c)>0) &&
    (pos(' ends ',c)>0)) return 10;
  if ((pos(' batch ',c)>0) || (pos(' echo hello ',c)>0) ||
    (pos(':done',q)>0) || (pos('%1',q)>0) || (pos('%2',q)>0) ||
    (pos(' percent two ',c)>0) && (pos(' argument ',c)>0)) return 9;
  return 0;
 }
}
