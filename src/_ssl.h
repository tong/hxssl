#ifndef _SSL_H_
#define _SSL_H_

value _SSL_load_error_strings();
value _OpenSSL_add_all_algorithms();
value _SSL_set_bio(value s, value rbio, value wbio);
value _BIO_new_ssl_connect(value ctx);
value _SSL_CTX_load_verify_locations(value ctx, value certFile, value certFolder);

#endif /* _SSL_H_ */
