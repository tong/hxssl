package sys.crypto;

#if cpp
import cpp.Lib;
#else
import neko.Lib;
#end

/**
	MD5 message-digest hash function
*/
class MD5 {
	
	public static inline function encode( s : String ) : String {
		#if cpp
		return _md5( s );
		#elseif neko
		return Lib.nekoToHaxe( _md5( Lib.haxeToNeko(s) ) );
		#end
	}
	
	static inline function _md5( s : String ) { return Lib.load( "ssl", "hxssl_md5", 1 )(s); }
	
}
