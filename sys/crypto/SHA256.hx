package sys.crypto;

#if cpp
import cpp.Lib;
#else
import neko.Lib;
#end

/**
*/
class SHA256 {

	public static inline var DIGEST_LENGTH = 32;
	
	public static inline function encode( s : String ) : String {
		#if cpp
		return _sha256( s );
		#elseif neko
		return Lib.nekoToHaxe( _sha256( Lib.haxeToNeko(s) ) );
		#end
	}
	
	static inline function _sha256( s : String ) { return Lib.load( "ssl", "hxssl_sha256", 1 )(s); }
	
}
