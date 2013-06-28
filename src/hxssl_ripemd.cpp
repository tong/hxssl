
#include <hx/CFFI.h>
#include <string.h>
#include <openssl/ripemd.h>

static value hxssl_ripemd160( value v ) {

	unsigned char digest[RIPEMD160_DIGEST_LENGTH];
	char* s = (char*)val_string(v);
 
	RIPEMD160_CTX ctx;
	RIPEMD160_Init( &ctx );
	RIPEMD160_Update( &ctx, s, strlen(s) );
	RIPEMD160_Final( digest, &ctx );
 	
	char md[RIPEMD160_DIGEST_LENGTH*2+1];
    for( int i = 0; i < RIPEMD160_DIGEST_LENGTH; i++ )
		sprintf( &md[i*2], "%02x", (unsigned int)digest[i] );

    return alloc_string( md );
}

DEFINE_PRIM( hxssl_ripemd160, 1 );
