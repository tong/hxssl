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

	public static inline function encode( s : String ) : String {
		#if (cpp||neko)
		return _encode( s );
		#elseif php
		return untyped __call__( "base64_encode", s );
		#end
	}
	
	public static inline function decode( s : String ) : String {
		#if (cpp||neko)
		return _decode( s );
		#elseif php
		return untyped __call__( "base64_decode", s );
		#end
	}
	
	#if (cpp||neko)
	private static inline function _encode( s : String ) return Lib.load( "hxssl", "hxssl_base64_encode", 1 )(s);
	private static inline function _decode( s : String ) return Lib.load( "hxssl", "hxssl_base64_decode", 1 )(s);
	#end
	
}
