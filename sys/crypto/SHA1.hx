package sys.crypto;

#if cpp
import cpp.Lib;
#else
import neko.Lib;
#end

class SHA1 {
	
	public static inline function encode( s : String ) : String {
		#if neko
		return Lib.nekoToHaxe( _sha1( untyped s.__s ) );
		#elseif cpp
		return _sha1( s );
		#end
	}
	
	static var _sha1 = Lib.load( "ssl", "hxssl_sha1", 1 );
	
}
