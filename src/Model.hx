import js.lib.Float32Array;
import js.lib.Int8Array;
import js.lib.ArrayBuffer;
import js.lib.DataView;
private typedef Table = { var rows:Int; var cols:Int; var scale:Float32Array; var w:Int8Array; }
class Model {
 public var d:Int; public var layers:Int; public var heads:Int; public var hidden:Int;
 var view:DataView; var offset=0; var emb:Table; var pos:Table;
 var q:Array<Table>=[]; var k:Array<Table>=[]; var v:Array<Table>=[]; var o:Array<Table>=[]; var f1:Array<Table>=[]; var f2:Array<Table>=[];
 var g1:Array<Float32Array>=[]; var g2:Array<Float32Array>=[]; var gf:Float32Array;
 var kc:Array<Int8Array>=[]; var vc:Array<Int8Array>=[]; var ks:Array<Float32Array>=[]; var vs:Array<Float32Array>=[];
 var x:Float32Array; var bh:Float32Array; var bq:Float32Array; var bt:Float32Array; var ba:Float32Array; var bm:Float32Array; var bs=new Float32Array(128);
 public var score=new Float32Array(97); public var activity:Array<Float>=[]; public var confidence:Float=0;
 function u16():Int { var n=view.getUint16(offset,true); offset+=2; return n; }
 function float():Float { var n=view.getFloat32(offset,true); offset+=4; if(!Math.isFinite(n)) throw 'Invalid model weight'; return n; }
 function gains():Float32Array { var a=new Float32Array(d); for(i in 0...d) a[i]=float(); return a; }
 function table(rows:Int,cols:Int):Table { var t:Table={rows:rows,cols:cols,scale:new Float32Array(rows),w:new Int8Array(rows*cols)}; for(r in 0...rows){t.scale[r]=float();for(c in 0...cols)t.w[r*cols+c]=view.getInt8(offset++);}return t; }
 public function new(data:ArrayBuffer) {
  view=new DataView(data); if(data.byteLength<12 || view.getUint32(0,false)!=0x544e5932)throw 'Choose a TNY2 model file.'; offset=4;
  d=u16(); layers=u16(); heads=u16(); hidden=u16();
  if(d<8||d>128||layers<1||layers>8||heads<1||d%heads!=0||hidden<8||hidden>512)throw 'Unsupported model dimensions.';
  emb=table(97,d);pos=table(128,d);
  for(l in 0...layers){g1.push(gains());q.push(table(d,d));k.push(table(d,d));v.push(table(d,d));o.push(table(d,d));g2.push(gains());f1.push(table(hidden,d));f2.push(table(d,hidden));kc.push(new Int8Array(128*d));vc.push(new Int8Array(128*d));ks.push(new Float32Array(128));vs.push(new Float32Array(128));}
  gf=gains(); if(offset!=data.byteLength)throw 'Model size does not match its header.';
  x=new Float32Array(d);bh=new Float32Array(d);bq=new Float32Array(d);bt=new Float32Array(d);ba=new Float32Array(d);bm=new Float32Array(hidden);
 }
 function mat(t:Table,a:Float32Array,b:Float32Array) {for(r in 0...t.rows){var s=0.;for(c in 0...t.cols)s+=t.w[r*t.cols+c]*a[c]; b[r]=s*t.scale[r];}}
 function norm(a:Float32Array,g:Float32Array,b:Float32Array){var s=0.;for(i in 0...d)s+=a[i]*a[i];s=1/Math.sqrt(s/d+0.00001);for(i in 0...d)b[i]=a[i]*s*g[i];}
 function save(a:Int8Array,p:Int,b:Float32Array):Float {var big=1e-20;for(i in 0...d)big=Math.max(big,Math.abs(b[i]));for(i in 0...d){var z=b[i]*127/big;a[p*d+i]=Std.int(z<0?z-0.5:z+0.5);}return big/127;}
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
 public static function clean(s:String):String {var q='';for(i in 0...s.length){var c=s.charCodeAt(i);if(c>=32&&c<=126&&q.length<72)q+=s.charAt(i);}q=StringTools.rtrim(q);if(q.toUpperCase()==q)q=q.toLowerCase();return q;}
}
