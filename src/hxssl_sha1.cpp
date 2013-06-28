
#include <hx/CFFI.h>
#include <string.h>
#include <openssl/sha.h>

static value hxssl_sha1( value v ) {

	unsigned char digest[SHA_DIGEST_LENGTH];
	char* s = (char*)val_string(v);
 
	SHA_CTX ctx;
	SHA1_Init( &ctx );
	SHA1_Update( &ctx, s, strlen(s) );
	SHA1_Final( digest, &ctx );
 
	char md[SHA_DIGEST_LENGTH*2+1];
	for( int i = 0; i < SHA_DIGEST_LENGTH; i++ )
		sprintf( &md[i*2], "%02x", (unsigned int)digest[i] );

	return alloc_string( md );
}

DEFINE_PRIM( hxssl_sha1, 1 );
