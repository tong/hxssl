
#include <hx/CFFI.h>
#include <string.h>
#include <openssl/md5.h>

static value hxssl_md5( value v ) {

	const char * s = val_string(v);
	int len = strlen(s);
	int n;
	MD5_CTX c;
	unsigned char digest[16];
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
	MD5_Final(digest, &c);

	for( n = 0; n < 16; ++n )
		snprintf( &(out[n * 2]), 16 * 2, "%02x", (unsigned int) digest[n] );

	return alloc_string( out );
}

DEFINE_PRIM( hxssl_md5, 1 );
