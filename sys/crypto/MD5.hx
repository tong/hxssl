package sys.crypto;

#if cpp
import cpp.Lib;
#else
import neko.Lib;
#end

class MD5 {
	
	public static function encode( s : String ) : String {
		#if neko
		return neko.Lib.nekoToHaxe( _md5(untyped s.__s) );
		#elseif cpp
		return _md5( s );
		#end
	}
	
	static var _md5 = Lib.load( "ssl", "hxssl_md5", 1 );
	
}
