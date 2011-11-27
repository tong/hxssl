package neko.crypto;

import neko.tls.Loader;

class Base64 {
	
	public static inline function encode( t : String ) : String return neko.Lib.nekoToHaxe(_encode(untyped t.__s))
	public static inline function decode( t : String ) : String return neko.Lib.nekoToHaxe(_decode(untyped t.__s))
	
	static var _encode = Loader.load( "hxssl_base64_encode", 1 );
	static var _decode = Loader.load( "hxssl_base64_decode", 1 );
	
}
