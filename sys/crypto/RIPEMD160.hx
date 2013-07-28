package sys.crypto;

#if cpp
import cpp.Lib;
#else
import neko.Lib;
#end

/**
	RIPEMD-160
*/
class RIPEMD160 {

	public static inline var DIGEST_LENGTH = 20;

	public static inline function encode( s : String ) : String {
		#if cpp
		return _ripemd160( s );
		#elseif neko
		return Lib.nekoToHaxe( _ripemd160( Lib.haxeToNeko(s) ) );
		#end
	}
	
	static inline function _ripemd160( s : String ) { return Lib.load( "hxssl", "hxssl_ripemd160", 1 )(s); }
	
}
