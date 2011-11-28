#include <string.h>
#include <openssl/bio.h>
#include <openssl/evp.h>
#include <openssl/buffer.h>
#include <neko.h>

static value hxssl_base64_encode(value t) {

	BIO *bmem, *b64;
	BUF_MEM *bptr;

	b64 = BIO_new(BIO_f_base64());
	bmem = BIO_new(BIO_s_mem());
	b64 = BIO_push(b64, bmem);
	BIO_write(b64, val_string(t), val_strlen(t));
	BIO_flush(b64);
	BIO_get_mem_ptr(b64, &bptr);

	char *buf = (char *) malloc(bptr->length);
	memcpy(buf, bptr->data, bptr->length - 1);
	buf[bptr->length - 1] = 0;

	BIO_free_all(b64);

	return alloc_string(buf);
}

static value hxssl_base64_decode(value t) {

	//TPDP
	BIO *b64, *bmem;

	unsigned char *input = val_string(t);
	int len = val_strlen(t);

	char *buffer = (char *) malloc(len);
	memset(buffer, 0, len);

	b64 = BIO_new(BIO_f_base64());
	bmem = BIO_new_mem_buf(input, len);
	bmem = BIO_push(b64, bmem);

	BIO_read(bmem, buffer, len);

	BIO_free_all(bmem);

	return alloc_string(buffer);
}

DEFINE_PRIM(hxssl_base64_encode,1);
DEFINE_PRIM(hxssl_base64_decode,1);
