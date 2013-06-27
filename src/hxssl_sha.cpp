
//#include "hxssl.h"
//#include <string.h>
//#include <hx/CFFI.h>
//#include <openssl/sha.h>


/*
static value hxssl_sha1(value v) {

	//unsigned char *SHA1( const unsigned char *d, unsigned long n, unsigned char *md );

	//SHA_CTX c;
	//SHA1_Init( &c );
	//unsigned char out[20];

	//unsigned char inp[] = (unsigned char *) val_string(v);
	const char * inp = (const char *) val_string(v);
	int len = val_strlen( v );
	const unsigned char out[20];
	//int len = strlen(inp);

	SHA1( inp, len, out );

	int i;
    for (i = 0; i < 20; i++) {
        printf("%02x ", out[i]);
    }
    printf("\n");


	return alloc_string(out);
}

static value hxssl_sha256( value v ) {

	unsigned char hash[SHA256_DIGEST_LENGTH];
	
	return val_false;


	/*
	SHA256_CTX ctx;
	if( !SHA256_Init( &ctx ) )
		return val_false;
	if( !SHA256_Update( &ctx, (unsigned char*)input, length ) )
		return val_false;
	if( !SHA256_Final( md, &ctx ) )
		return val_false;
	return val_true;
	* /
}

//DEFINE_PRIM( hxssl_sha1, 1 );
DEFINE_PRIM( hxssl_sha256, 1 );
*/
