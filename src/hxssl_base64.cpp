
#include <string.h>
#include <hx/CFFI.h>
#include <openssl/bio.h>
#include <openssl/evp.h>
#include <openssl/buffer.h>

// Calculates the length of a decoded base64 string
static int calcDecodeLength( const char* b64input ) {
	int len = strlen(b64input);
	int padding = 0;
	if( b64input[len-1] == '=' && b64input[len-2] == '=' ) //last two chars are =
		padding = 2;
	else if( b64input[len-1] == '=' ) //last char is =
		padding = 1;
	return (int)len*0.75 - padding;
}

static value hxssl_base64_encode(value v) {

	BIO *bmem, *b64;
	BUF_MEM *bptr;

	const char * s = val_string(v);
	//int len = 4 * ceil((double) strlen(s) / 3);

	b64 = BIO_new(BIO_f_base64());
	bmem = BIO_new(BIO_s_mem());
	b64 = BIO_push(b64, bmem);
	BIO_write(b64, s, strlen(s));
	BIO_flush(b64);
	BIO_get_mem_ptr(b64, &bptr);

	char *buf = (char *) malloc(bptr->length);
	memcpy(buf, bptr->data, bptr->length - 1);
	buf[bptr->length - 1] = 0;

	BIO_free_all(b64);

	return alloc_string( buf );
}

static value hxssl_base64_decode(value v) {

	/*

	BIO *bmem, *b64;

	unsigned char * s = (unsigned char *) val_string(v);
	int len = (int) val_strlen(v);

	char *buf = (char *) malloc(len + 1);
	memset( buf, 0, len + 1 );

	b64 = BIO_new( BIO_f_base64() );
	BIO_set_flags( b64, BIO_FLAGS_BASE64_NO_NL );
	bmem = BIO_new_mem_buf( s, len );
	bmem = BIO_push( b64, bmem );

	BIO_read( bmem, buf, len );
//	buf[len] = '\0';

	printf(buf);

	BIO_free_all( bmem );

	return alloc_string( buf );
	*/

	BIO *bio, *b64;

	char* msg = (char*) val_string(v);
	int decodeLen = calcDecodeLength(msg);
	int len = 0;

	char* buf = (char*) malloc( decodeLen+1 );
	FILE* stream = fmemopen( msg, strlen(msg), "r" );
 
	b64 = BIO_new( BIO_f_base64() );
	bio = BIO_new_fp( stream, BIO_NOCLOSE );
	bio = BIO_push( b64, bio );
	BIO_set_flags( bio, BIO_FLAGS_BASE64_NO_NL ); //Do not use newlines to flush buffer
	len = BIO_read( bio, buf, strlen(msg) );
	//Can test here if len == decodeLen - if not, then return an error
	(buf)[len] = '\0';
 
	BIO_free_all( bio );
	fclose( stream );

	return alloc_string( buf );
}

DEFINE_PRIM( hxssl_base64_encode, 1 );
DEFINE_PRIM( hxssl_base64_decode, 1 );
