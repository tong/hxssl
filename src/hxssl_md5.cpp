
#define _CRT_SECURE_NO_WARNINGS
#if _MSC_VER
#define snprintf _snprintf
#endif

#include <hx/CFFI.h>
#include <string.h>
#include <openssl/md5.h>

static value hxssl_md5( value v, value raw ) {

	const char * s = val_string(v);
	bool _raw = val_bool( raw );

	int len = strlen(s);
	int n;
	MD5_CTX c;

	unsigned char digest[MD5_DIGEST_LENGTH];
	char *out = (char*) malloc(33);

	MD5_Init(&c);
	while( len > 0 ) {
		if (len > 512) {
			MD5_Update(&c, s, 512);
		} else {
			MD5_Update( &c, s, len );
		}
		len -= 512;
		s += 512;
	}
	MD5_Final( digest, &c );

	//TODO raw/hex encoding

	/*
	if( raw ) {
		//TODO
		//string result;
		char * result;
		char buf[32];
		for( n = 0; n < 16; n++ ) {
		    sprintf( buf, "%02x", digest[n] );
			//   result.append( buf );
			strcpy( result, buf );
		
		}
		return alloc_string( result );
		//return alloc_string( (char*)digest );
	    //for( int i = 0; i < 16; ++i )
	     // digest[i] = (unsigned char)( m_state.abcd[i >> 2] >> ( ( i & 3 ) << 3 ) );
    	//return std::string( (char*)digest, 16 );
		
	} else {
		for( n = 0; n < 16; ++n )
			snprintf( &(out[n*2]), 16*2, "%02x", (unsigned int) digest[n] );
		return alloc_string( out );
  	}
  	*/

	/*
	if( raw ) {
		return alloc_string( (char*)digest );
	} else {
		for( n = 0; n < 16; ++n )
			snprintf( &(out[n * 2]), 16 * 2, "%02x", (unsigned int) digest[n] );
	}
	return alloc_string( out );
	*/

	for( n = 0; n < 16; ++n )
		snprintf( &(out[n * 2]), 16 * 2, "%02x", (unsigned int) digest[n] );
	return alloc_string( out );
}

DEFINE_PRIM( hxssl_md5, 2 );
