
#include "neko.h"
#include "openssl/evp.h"

DEFINE_KIND(k_evp_md);

//const EVP_MD *EVP_sha1(void);
/*value _EVP_sha1(){
	EVP_MD* tmp = EVP_sha1();
	return alloc_abstract(k_evp_md, tmp);
	return val_null;
}

DEFINE_PRIM(_EVP_sha1, 0);*/
