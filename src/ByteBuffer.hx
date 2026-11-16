#if js
typedef ByteBuffer = js.lib.Int8Array;
#else
/** Signed-byte storage shared by the non-JavaScript targets. */
abstract ByteBuffer(haxe.io.Bytes) {
 public inline function new(length:Int) this = haxe.io.Bytes.alloc(length);
 @:arrayAccess public inline function get(index:Int):Int {
  var value = this.get(index);
  return value >= 128 ? value - 256 : value;
 }
 @:arrayAccess public inline function set(index:Int, value:Int):Int {
  this.set(index, value);
  return value;
 }
}
#end
