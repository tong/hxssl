#include <neko.h>
#include <string.h>
#include <openssl/hmac.h>
#include <openssl/evp.h>
#include "_hmac.h"

//unsigned char *HMAC(const EVP_MD *evp_md, const void *key, int key_len,
//		    const unsigned char *d, size_t n, unsigned char *md,
//		    unsigned int *md_len);

DEFINE_KIND( k_unsigned_char);

value _HMAC(const value evp_md, const value key, value key_len, const value d,
		value n, value md, value md_len) {
	return alloc_abstract(
			k_unsigned_char,
			HMAC((EVP_MD*) val_data(evp_md), val_data(key), val_int(key_len),
					(unsigned char*) val_data(d), val_int(n),
					(unsigned char*) val_data(md),
					(unsigned int*) val_data(md_len)));
}

value _HMAC_EVP_sha1(value key, value d) {
	unsigned int tmp;
	unsigned char md[255];
	HMAC(EVP_sha1(), val_string(key), strlen(val_string(key)),
			(unsigned char*) val_string(d), strlen(val_string(d)), md, &tmp);
	md[tmp] = '\0';
	return alloc_string((char*) md);
}

DEFINE_PRIM (_HMAC, 7);
DEFINE_PRIM (_HMAC_EVP_sha1, 2);
