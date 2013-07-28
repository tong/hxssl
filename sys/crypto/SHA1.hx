package sys.crypto;

#if cpp
import cpp.Lib;
#else
import neko.Lib;
#end

/**
	SHA-1 (Secure Hash Algorithm)
*/
class SHA1 {

	public static inline var DIGEST_LENGTH = 20;
	
	public static inline function encode( s : String ) : String {
		#if cpp
		return _sha1( s );
		#elseif neko
		return Lib.nekoToHaxe( _sha1( Lib.haxeToNeko(s) ) );
		#elseif php
		return untyped __call__( "sha1", s );
		#end
	}
	
	static inline function _sha1( s : String ) return Lib.load( "hxssl", "hxssl_sha1", 1 )(s);
	
}
