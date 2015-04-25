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

	public static inline var DIGEST_LENGTH = 16;
	
	public static inline function encode( s : String, raw : Bool = false ) : String {
		if( raw )
			throw( "MD5 raw encoding not implemented" );
		#if (cpp||neko)
		return _md5( s, raw );
		#elseif php
		return untyped __call__( "md5", s, raw );
		#end
	}
	
	static inline function _md5( s : String, raw : Bool ) return Lib.load( "hxssl", "hxssl_md5", 2 )(s,raw);
	
}
