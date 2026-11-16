import haxe.io.Bytes;
private typedef Table = { var rows:Int; var cols:Int; var scale:FloatBuffer; var w:ByteBuffer; }
class Model {
 public var d:Int; public var layers:Int; public var heads:Int; public var hidden:Int;
 var data:Bytes; var offset=0; var emb:Table; var pos:Table;
 var q:Array<Table>=[]; var k:Array<Table>=[]; var v:Array<Table>=[]; var o:Array<Table>=[]; var f1:Array<Table>=[]; var f2:Array<Table>=[];
 var g1:Array<FloatBuffer>=[]; var g2:Array<FloatBuffer>=[]; var gf:FloatBuffer;
 var kc:Array<ByteBuffer>=[]; var vc:Array<ByteBuffer>=[]; var ks:Array<FloatBuffer>=[]; var vs:Array<FloatBuffer>=[];
 var x:FloatBuffer; var bh:FloatBuffer; var bq:FloatBuffer; var bt:FloatBuffer; var ba:FloatBuffer; var bm:FloatBuffer; var bs=new FloatBuffer(128);
 public var score=new FloatBuffer(97); public var activity:Array<Float>=[]; public var confidence:Float=0;
 function requireBytes(n:Int) { if(offset > data.length - n) throw 'Model file is truncated.'; }
 function signedByte():Int { requireBytes(1); var n=data.get(offset++); return n>=128?n-256:n; }
 function u16():Int { requireBytes(2); var n=data.getUInt16(offset); offset+=2; return n; }
 function float():Float { requireBytes(4); var n=data.getFloat(offset); offset+=4; if(!Math.isFinite(n)) throw 'Invalid model weight'; return n; }
 function gains():FloatBuffer { var a=new FloatBuffer(d); for(i in 0...d) a[i]=float(); return a; }
 function table(rows:Int,cols:Int):Table { var t:Table={rows:rows,cols:cols,scale:new FloatBuffer(rows),w:new ByteBuffer(rows*cols)}; for(r in 0...rows){t.scale[r]=float();for(c in 0...cols)t.w[r*cols+c]=signedByte();}return t; }
 public function new(data:Bytes) {
  this.data=data; if(data.length<12 || data.getString(0,4)!='TNY2')throw 'Choose a TNY2 model file.'; offset=4;
  d=u16(); layers=u16(); heads=u16(); hidden=u16();
  if(d<8||d>128||layers<1||layers>8||heads<1||d%heads!=0||hidden<8||hidden>512)throw 'Unsupported model dimensions.';
  emb=table(97,d);pos=table(128,d);
  for(l in 0...layers){g1.push(gains());q.push(table(d,d));k.push(table(d,d));v.push(table(d,d));o.push(table(d,d));g2.push(gains());f1.push(table(hidden,d));f2.push(table(d,hidden));kc.push(new ByteBuffer(128*d));vc.push(new ByteBuffer(128*d));ks.push(new FloatBuffer(128));vs.push(new FloatBuffer(128));}
  gf=gains(); if(offset!=data.length)throw 'Model size does not match its header.';
  x=new FloatBuffer(d);bh=new FloatBuffer(d);bq=new FloatBuffer(d);bt=new FloatBuffer(d);ba=new FloatBuffer(d);bm=new FloatBuffer(hidden);
 }
 function mat(t:Table,a:FloatBuffer,b:FloatBuffer) {for(r in 0...t.rows){var s=0.;for(c in 0...t.cols)s+=t.w[r*t.cols+c]*a[c]; b[r]=s*t.scale[r];}}
 function norm(a:FloatBuffer,g:FloatBuffer,b:FloatBuffer){var s=0.;for(i in 0...d)s+=a[i]*a[i];s=1/Math.sqrt(s/d+0.00001);for(i in 0...d)b[i]=a[i]*s*g[i];}
 function save(a:ByteBuffer,p:Int,b:FloatBuffer):Float {var big=1e-20;for(i in 0...d)big=Math.max(big,Math.abs(b[i]));for(i in 0...d){var z=b[i]*127/big;a[p*d+i]=Std.int(z<0?z-0.5:z+0.5);}return big/127;}
 public function step(tok:Int,p:Int) {
  var hd=Std.int(d/heads);
  for(i in 0...d)x[i]=emb.w[tok*d+i]*emb.scale[tok]+pos.w[p*d+i]*pos.scale[p];
  for(l in 0...layers){norm(x,g1[l],bh);mat(k[l],bh,bt);ks[l][p]=save(kc[l],p,bt);mat(v[l],bh,bt);vs[l][p]=save(vc[l],p,bt);mat(q[l],bh,bq);
   for(h in 0...heads){var big=-1e30;for(j in 0...p+1){var s=0.;for(i in 0...hd)s+=bq[h*hd+i]*kc[l][j*d+h*hd+i];s=s*ks[l][j]/Math.sqrt(hd);bs[j]=s;big=Math.max(big,s);}var sum=0.;for(j in 0...p+1){bs[j]=Math.exp(bs[j]-big);sum+=bs[j];}for(i in 0...hd)ba[h*hd+i]=0;for(j in 0...p+1){var s=bs[j]*vs[l][j]/sum;for(i in 0...hd)ba[h*hd+i]+=s*vc[l][j*d+h*hd+i];}}
   mat(o[l],ba,bt);for(i in 0...d)x[i]+=bt[i];norm(x,g2[l],bh);mat(f1[l],bh,bm);var s=0.;for(i in 0...hidden){bm[i]=Math.max(0,bm[i]);s+=bm[i];}activity[l]=s/hidden;mat(f2[l],bm,bt);for(i in 0...d)x[i]+=bt[i];
  }norm(x,gf,bh);mat(emb,bh,score);
 }
 public function pick(creativity:Int):Int {var best=0;for(i in 1...97)if(score[i]>score[best])best=i;var tok=best;
  if(creativity>0){var sum=0.;for(i in 0...97){bs[i]=Math.exp((score[i]-score[best])/(creativity/5));if(bs[i]<0.15)bs[i]=0;sum+=bs[i];}var r=Math.random()*sum;for(i in 0...97){r-=bs[i];if(r<0&&bs[i]>0){tok=i;break;}}}
  var sum=0.;for(i in 0...97)sum+=Math.exp(score[i]-score[tok]);confidence=1/sum;return tok;
 }
 /** Answer one independent question. The optional callback receives each generated character. */
 public function answer(question:String, creativity:Int=0, ?onLetter:String->Void):String {
  if(creativity<0||creativity>9)throw 'Creativity must be between 0 and 9.';
  var text=clean(question);
  if(text.length==0)throw 'Enter a printable ASCII question.';
  var p=0;
  for(i in 0...text.length)step(text.charCodeAt(i)-30,p++);
  step(1,p++);
  var out=new StringBuf();
  while(p<128){var tok=pick(creativity);if(tok<=1)break;var letter=String.fromCharCode(tok+30);out.add(letter);if(onLetter!=null)onLetter(letter);step(tok,p++);}
  return out.toString();
 }
 public static function clean(s:String):String {var q='';for(i in 0...s.length){var c=s.charCodeAt(i);if(c>=32&&c<=126&&q.length<72)q+=s.charAt(i);}q=StringTools.rtrim(q);if(q.toUpperCase()==q)q=q.toLowerCase();return q;}
}
