package sys.crypto;

#if cpp
import cpp.Lib;
#elseif neko
import neko.Lib;
#end

/**
	Encode/Decode base64
*/
class Base64 {

	/**
	*/
	public static inline function encode( s : String ) : String {
		#if neko
		return Lib.nekoToHaxe( _encode( untyped s.__s ) );
		#else
		return _encode( s );
		#end
	}
	
	/**
	*/
	public static inline function decode( s : String ) : String {
		#if neko
		return Lib.nekoToHaxe( _decode( s ) );
		#elseif cpp
		return _decode( s );
		#end
	}
	
	private static var _encode = std( "base64_encode", 1 );
	private static var _decode = std( "base64_decode", 1 );
	
	private static inline function std( f : String, args : Int ) : Dynamic {
		return Lib.load( 'ssl', 'hxssl_'+f, args );
	}
	
}
