#include "neko.h"
#include "stdio.h"
#include "val_void.h"
#include "openssl/ssl.h"
#include "openssl/bio.h"
#include "openssl/err.h"

DEFINE_KIND( k_ssl_ctx_pointer);
DEFINE_KIND( k_ssl_method_pointer);
DEFINE_KIND( k_ssl);
DEFINE_KIND( k_ssl_ctx);

//void	SSL_load_error_strings(void );
value _SSL_load_error_strings() {
	SSL_load_error_strings();
	return VAL_VOID;
}

//void OpenSSL_add_all_algorithms)(void );
value _OpenSSL_add_all_algorithms() {
	OpenSSL_add_all_algorithms();
	return VAL_VOID;
}

//int SSL_library_init(void );
value _SSL_library_init() {
	SSL_library_init();
	return VAL_VOID;
}
//SSL_CTX *SSL_CTX_new(SSL_METHOD *meth);
value _SSL_CTX_new(value meth) {
	SSL_CTX* ssl_ctx = SSL_CTX_new((SSL_METHOD*) val_data(meth));
	return alloc_abstract(k_ssl_ctx_pointer, ssl_ctx);
}
//int SSL_CTX_load_verify_locations(SSL_CTX *ctx, const char *CAfile,
//	const char *CApath);
value _SSL_CTX_load_verify_locations(value ctx, /*value CAfile, */value CApath) {
	return alloc_int(SSL_CTX_load_verify_locations((SSL_CTX*) val_data(ctx), /*val_string(CAfile)*/
	NULL, val_string(CApath)));
}
//BIO *BIO_new_ssl_connect(SSL_CTX *ctx);
value _BIO_new_ssl_connect(value ctx) {
	return alloc_abstract(k_ssl_ctx_pointer, BIO_new_ssl_connect(
			(SSL_CTX*) val_data(ctx)));
}
//#define BIO_get_ssl(b,sslp)	BIO_ctrl(b,BIO_C_GET_SSL,0,(char *)sslp)
//long	BIO_ctrl(BIO *bp,int cmd,long larg,void *parg);

value _BIO_get_ssl(value b/*, value sslp*/) {
	SSL* r_ssl = NULL;
	long r_bio_get_ssl = BIO_get_ssl((BIO*) val_data(b), &r_ssl);
	return alloc_abstract(k_ssl, r_ssl);
}

//#define SSL_set_mode(ssl,op) SSL_ctrl((ssl),SSL_CTRL_MODE,(op),NULL)
//long	SSL_ctrl(SSL *ssl,int cmd, long larg, void *parg);

value _SSL_set_mode(value ssl, value op) {
	long response = SSL_set_mode((SSL*) val_data(ssl), val_int(op));
	return alloc_best_int(response);
}

//#define SSL_MODE_AUTO_RETRY 0x00000004L
value _SSL_MODE_AUTO_RETRY() {
	return alloc_best_int(0x00000004L);
}

//SSL_METHOD *SSLv23_client_method(void);
value _SSLv23_client_method() {
	return alloc_abstract(k_ssl_method_pointer, SSLv23_client_method());
}
//SSL *	SSL_new(SSL_CTX *ctx);
value _SSL_new(value ssl_ctx) {
	SSL* ssl = SSL_new((SSL_CTX*) val_data(ssl_ctx));
	return alloc_abstract(k_ssl_ctx, ssl);
}
//void	SSL_set_bio(SSL *s, BIO *rbio,BIO *wbio);
value _SSL_set_bio(value s, value rbio, value wbio) {
	SSL_set_bio((SSL*) val_data(s), (BIO*) val_data(rbio),
			(BIO*) val_data(wbio));
	return VAL_VOID;
}
value _BIO_NOCLOSE() {
	return alloc_int(BIO_NOCLOSE);
}

//int 	SSL_connect(SSL *ssl);
value _SSL_connect(value ssl) {
	int rsc = SSL_connect((SSL*) val_data(ssl));
	return alloc_int(rsc);
}
//void SSL_CTX_set_verify(SSL_CTX *ctx,int mode,
//											int (*callback)(int, X509_STORE_CTX *));
value _SSL_CTX_set_verify(value ctx, value mode,
		value(*callback)( value, value)) {
	//SSL_CTX_set_verify((SSL_CTX*) val_data(ctx), val_int(mode), );
	return VAL_VOID;
}
//int	SSL_set_fd(SSL *s, int fd);
value _SSL_set_fd(value s, value fd) {
	return alloc_int(SSL_set_fd((SSL*) val_data(s), val_int(fd)));
}
//void SSL_CTX_set_verify_depth(SSL_CTX *ctx,int depth);
value _SSL_CTX_set_verify_depth(value ctx, value depth) {
	SSL_CTX_set_verify_depth((SSL_CTX*) val_data(ctx), val_int(depth));
	return VAL_VOID;
}

//int 	SSL_read(SSL *ssl,void *buf,int num);
value _SSL_read(value ssl, value buf, value num) {
	return alloc_int(
			SSL_read((SSL*) val_data(ssl), val_data(buf), val_int(num)));
}
//int 	SSL_write(SSL *ssl,const void *buf,int num);
value _SSL_write(value ssl, const value buf, value num) {
	return alloc_int(SSL_write((SSL*) val_data(ssl), val_data(buf),
			val_int(num)));
}

value __SSL_write(value ssl, value data) {
	const char *cdata;
	int datalen, slen;
	/*	val_check_kind(o,k_socket);
	 val_check(data,string);*/
	cdata = val_string(data);
	datalen = val_strlen(data);
	while (datalen > 0) {
		slen = SSL_write((SSL*) val_data(ssl), cdata, datalen);
		//if( slen == SOCKET_ERROR )
		//	return block_error();
		cdata += slen;
		datalen -= slen;
	}
	return val_true;
}
value __SSL_read(value ssl) {
	buffer b;
	char buf[256];
	int len;
	//val_check_kind(o,k_socket);
	b = alloc_buffer(NULL);
	while (true) {
		len = SSL_read((SSL*) val_data(ssl), buf, 256);
		//if( len == SOCKET_ERROR )
		//	return block_error();
		if (len == 0)
			break;
		buffer_append_sub(b, buf, len);
	}
	return buffer_to_string(b);
}
value SSL_send_char(value ssl, value v) {
	int c;
	unsigned char cc;
	//val_check_kind(o,k_socket);
	//val_check(v,int);
	c = val_int(v);
	//if( c < 0 || c > 255 ) neko_error();
	cc = (unsigned char) c;
	//if( send(val_sock(o),&cc,1,MSG_NOSIGNAL) == SOCKET_ERROR )	return block_error();
	SSL_write((SSL*) val_data(ssl), &cc, 1);
	return val_true;
}
value SSL_send(value ssl, value data, value pos, value len) {
	int p, l, dlen;
	//val_check_kind(o,k_socket);
	//val_check(data,string);
	//val_check(pos,int);
	//val_check(len,int);
	p = val_int(pos);
	l = val_int(len);
	dlen = val_strlen(data);
	if (p < 0 || l < 0 || p > dlen || p + l > dlen)
		neko_error();
	//dlen = send(val_sock(o), val_string(data) + p , l, MSG_NOSIGNAL);
	dlen = SSL_write((SSL*) ssl, val_string(data) + p, l);
	//if( dlen == SOCKET_ERROR )
	//	return block_error();
	return alloc_int(dlen);
}
value SSL_recv(value ssl, value data, value pos, value len) {
	int p, l, dlen;
	/*
	 val_check_kind(ssl,k_ssl);
	 val_check(data,string);
	 val_check(pos,int);
	 val_check(len,int);
	 */
	p = val_int(pos);
	l = val_int(len);
	dlen = val_strlen(data);
	if (p < 0 || l < 0 || p > dlen || p + l > dlen)
		neko_error();
	dlen = SSL_read((SSL*) val_data(ssl), val_string(data) + p, l);//, MSG_NOSIGNAL);
	//if( dlen == SOCKET_ERROR )
	//	return block_error();
	return alloc_int(dlen);
}

value SSL_recv_char(value ssl) {
	unsigned char cc;
	//val_check_kind(o,k_socket);
	//if(
	int res = SSL_read((SSL*) val_data(ssl), &cc, 1);/*,MSG_NOSIGNAL)*///<= 0
	//) return block_error();
	return alloc_int(cc);
}

/*
 value SSL_recv_bytes( value ssl ) {
 }
 */

//int SSL_shutdown(SSL *s);
value _SSL_shutdown(value ssl) {
	return alloc_int(SSL_shutdown((SSL*) val_data(ssl)));
}

DEFINE_PRIM(_SSL_load_error_strings, 0);
DEFINE_PRIM(_OpenSSL_add_all_algorithms, 0);
DEFINE_PRIM(_SSL_library_init,0);
DEFINE_PRIM(_SSL_CTX_new,1);
DEFINE_PRIM(_SSL_CTX_load_verify_locations,2) //!!
DEFINE_PRIM(_BIO_new_ssl_connect,1);
DEFINE_PRIM(_BIO_get_ssl,1);
DEFINE_PRIM(_SSL_set_mode, 2);
DEFINE_PRIM(_SSL_MODE_AUTO_RETRY, 0);
DEFINE_PRIM(_SSLv23_client_method, 0);
DEFINE_PRIM(_SSL_new, 1);
DEFINE_PRIM(_SSL_set_bio, 3);
DEFINE_PRIM(_BIO_NOCLOSE, 0);
DEFINE_PRIM(_SSL_connect, 1);
DEFINE_PRIM(_SSL_set_fd, 2);
DEFINE_PRIM(_SSL_CTX_set_verify_depth, 2);
DEFINE_PRIM(_SSL_read, 3);
DEFINE_PRIM(_SSL_write, 3);
DEFINE_PRIM(__SSL_write, 2);
DEFINE_PRIM(__SSL_read, 1);
DEFINE_PRIM(SSL_send_char, 2);
DEFINE_PRIM(SSL_send, 4);
DEFINE_PRIM(SSL_recv, 4);
DEFINE_PRIM(SSL_recv_char, 1);
DEFINE_PRIM(_SSL_shutdown, 1);
