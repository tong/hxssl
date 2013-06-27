
#include <string.h>
#include <hx/CFFI.h>
#include <openssl/bio.h>
#include <openssl/evp.h>
#include <openssl/buffer.h>


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

	return alloc_string(buf);
}


static value hxssl_base64_decode(value v) {

	BIO *b64, *bmem;

	unsigned char * s = (unsigned char *) val_string(v);
	int len = (int) val_strlen(v);

	char *buf = (char *) malloc(len + 1);
	memset(buf, 0, len + 1);

	b64 = BIO_new(BIO_f_base64());
	BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
	bmem = BIO_new_mem_buf(s, len);
	bmem = BIO_push(b64, bmem);

	BIO_read(bmem, buf, len);
//	buf[len] = '\0';

	BIO_free_all(bmem);

	return alloc_string(buf);
}


DEFINE_PRIM( hxssl_base64_encode, 1 );
DEFINE_PRIM( hxssl_base64_decode, 1 );
