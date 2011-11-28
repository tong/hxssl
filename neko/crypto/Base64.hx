package neko.crypto;

import neko.tls.Loader;
using StringTools;

class Base64 {
	
	public static function encode( t : String ) : String {
		var s : String = neko.Lib.nekoToHaxe( _encode( untyped t.__s ) );
		//trace(s);
		return s.replace( '\n', '' );
	}
	
	public static function decode( t : String ) : String {
		var s : String = neko.Lib.nekoToHaxe( _decode( untyped (t).__s ) );
		//s = s.substr(0,s.length-1);
		//trace(s);
		//var s : String = neko.Lib.nekoToHaxe( _decode( untyped t.__s ) );
		return s;
		//return s.replace( '\n', '' );
		//return _decode(untyped t.__s ).replace("\n","");
		//return neko.Lib.nekoToHaxe( _decode(untyped t.__s) )
	}
	
	static var _encode = Loader.load( "hxssl_base64_encode", 1 );
	static var _decode = Loader.load( "hxssl_base64_decode", 1 );
	
}
