
#include <hx/CFFI.h>
#include <string.h>
#include <openssl/sha.h>

static value hxssl_sha256( value v ) {

	unsigned char digest[SHA256_DIGEST_LENGTH];
	char* s = (char*)val_string(v);
 
	SHA256_CTX ctx;
	SHA256_Init( &ctx );
	SHA256_Update( &ctx, s, strlen(s) );
	SHA256_Final( digest, &ctx );
 
	char md[SHA256_DIGEST_LENGTH*2+1];
	for( int i = 0; i < SHA256_DIGEST_LENGTH; i++ )
		sprintf( &md[i*2], "%02x", (unsigned int)digest[i] );

	return alloc_string( md );
}

DEFINE_PRIM( hxssl_sha256, 1 );
