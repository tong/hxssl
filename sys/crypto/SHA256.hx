package sys.crypto;

import #if cpp cpp.Lib #elseif neko neko.Lib #end;

/**
	SHA-256

	Cryptographic hash function designed by the U.S. National Security Agency (NSA)
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
	
	static inline function _sha256( s : String ) return Lib.load( "hxssl", "hxssl_sha256", 1 )(s);
	
}
