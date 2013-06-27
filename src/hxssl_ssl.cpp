
#define IMPLEMENT_API
#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
	#define NEKO_COMPATIBLE
#endif

#include <hx/CFFI.h>
#include <stdio.h>
#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/ssl.h>

#define VAL_NULL alloc_int(0) // TODO neko error on val_null ???

DEFINE_KIND( k_ssl_method_pointer);
DEFINE_KIND( k_ssl_ctx_pointer );
DEFINE_KIND( k_ssl_ctx );
DEFINE_KIND( k_BIO );

static value hxssl_SSL_library_init() {
	SSL_library_init();
	return VAL_NULL;
}

static value hxssl_SSL_load_error_strings() {
	SSL_load_error_strings();
	return VAL_NULL;
}

static value hxssl_SSL_new( value ctx ) {
	SSL* ssl = SSL_new( (SSL_CTX*) val_data(ctx) );
	return alloc_abstract( k_ssl_ctx, ssl );
}

static value hxssl_SSL_close( value ssl ) {
	SSL_free((SSL*) val_data(ssl));
	return VAL_NULL;
}

static value hxssl_SSL_free( value ssl ) {
	SSL_free( (SSL*) val_data(ssl) );
	return VAL_NULL;
}

static value hxssl_SSL_set_bio( value s, value rbio, value wbio ) {
	SSL_set_bio( (SSL*) val_data(s), (BIO*) val_data(rbio), (BIO*) val_data(wbio) );
	return VAL_NULL;
}

static value hxssl_SSL_connect( value ssl ) {
	int r = SSL_connect( (SSL*) val_data(ssl) );
	return alloc_int( r );
}

static value hxssl_SSL_shutdown( value ssl ) {
	return alloc_int( SSL_shutdown( (SSL*) val_data(ssl) ) );
}

static value hxssl_SSLv23_client_method() {
	return alloc_abstract( k_ssl_method_pointer, (SSL_METHOD*)SSLv23_client_method() );
}
static value hxssl_TLSv1_client_method() {
	return alloc_abstract( k_ssl_method_pointer, (SSL_METHOD*)TLSv1_client_method() );
}

static value hxssl_SSL_CTX_new( value m ) {
	SSL_CTX * ctx = SSL_CTX_new( (const SSL_METHOD*) val_data(m) );
	return alloc_abstract( k_ssl_ctx_pointer, ctx );
}
static value hxssl_SSL_CTX_close(value ssl_ctx) {
	SSL_CTX_free((SSL_CTX*) val_data(ssl_ctx));
	return VAL_NULL;
}

static value hxssl_SSL_send_char(value ssl, value v) {
	//val_check_kind();
	//val_check(v,int);
	int c = val_int(v);
	if( c < 0 || c > 255 )
		neko_error();
	unsigned char cc;
	cc = (unsigned char) c;
	//if( send(val_sock(o),&cc,1,MSG_NOSIGNAL) == SOCKET_ERROR )	return block_error();
	SSL_write((SSL*) val_data(ssl), &cc, 1 );
	return val_true;
}

static value hxssl_SSL_send( value ssl, value data, value pos, value len ) {
	//val_check( data, string );
	//val_check( pos, int );
	//val_check( len, int );
	int p = val_int( pos );
	int l = val_int( len );
	int dlen = val_strlen( data );
	if( p < 0 || l < 0 || p > dlen || p + l > dlen )
		neko_error();
	dlen = SSL_write( (SSL*) ssl, val_string(data) + p, l );
	//if( dlen == SOCKET_ERROR )
	//	return block_error();
	return alloc_int(dlen);
}

static value hxssl_SSL_recv( value ssl, value data, value pos, value len ) {
	//val_check_kind(ssl,k_ssl);
	//val_check(data,string);
	//val_check(pos,int);
	//val_check(len,int);
	int p = val_int( pos );
	int l = val_int( len );
	//dlen = val_strlen(data);
	//printf("hxssl_SSL_recv %i %i\n", p, l );
	void * buf = (void *) (val_string(data) + p);
	SSL *_ssl = (SSL*) val_data(ssl);
	int dlen = SSL_read( _ssl, buf, l );
	//if( p < 0 || l < 0 || p > dlen || p + l > dlen )
	//	neko_error();
	if( dlen == 0 ) {
		//int err = SSL_get_error( _ssl, dlen );
		neko_error();
	}
	//if( dlen == SOCKET_ERROR )
	return alloc_int( dlen );
}

static value hxssl_SSL_recv_char(value ssl) {
	unsigned char c;
	int r = SSL_read( (SSL*) val_data(ssl), &c, 1 );
	if( r <= 0 )
		neko_error();
	return alloc_int( c );
}

static value hxssl_BIO_NOCLOSE() {
	return alloc_int( BIO_NOCLOSE );
}

static value hxssl_BIO_new_socket( value sock, value close_flag ) {
	int sock_ = ((int_val) val_data(sock));
	BIO* bio = BIO_new_socket(sock_, val_int(close_flag));
	return alloc_abstract( k_BIO, bio );
}

static  value hxssl___SSL_read( value ssl ) {
	buffer b;
	char buf[256];
	int len;
	b = alloc_buffer(NULL);
	while( true ) {
		len = SSL_read((SSL*) val_data(ssl), buf, 256);
		//if( len == SOCKET_ERROR )
		//	return block_error();
		if( len == 0 )
			break;
		buffer_append_sub(b, buf, len);
	}
	return buffer_to_string(b);
}

static value hxssl___SSL_write( value ssl, value data ) {
	const char *cdata;
	int datalen, slen;
	//val_check_kind(o,k_socket);
	//val_check(data,string);
	cdata = val_string( data );
	datalen = val_strlen( data );
	while( datalen > 0 ) {
		slen = SSL_write( (SSL*) val_data(ssl), cdata, datalen );
		//if( slen == SOCKET_ERROR )
		//	return block_error();
		cdata += slen;
		datalen -= slen;
	}
	//return val_true;
	return VAL_NULL;
}

static value hxssl_SSL_CTX_load_verify_locations( value ctx, value certFile, value certFolder ) {
	const char *sslCertFile;
	const char *sslCertFolder;
	if( !val_is_string( certFile ) )
		sslCertFile = "/etc/ssl/certs/ca-certificates.crt"; //TODO
	else
		sslCertFile = val_string( certFile );
	if( !val_is_string( certFolder ) )
		sslCertFolder = "/etc/ssl/certs"; //TODO
	else
		sslCertFolder = val_string( certFolder );
	//printf( "SSL cert file: %s\n", sslCertFile );
	//printf( "SSL cert folder: %s\n", sslCertFolder );
	int r = SSL_CTX_load_verify_locations( (SSL_CTX*) val_data(ctx), sslCertFile, sslCertFolder );
	//printf( "Cert verfification result: %i\n", r );
	return alloc_int( r );
}

//TODO Verify callback
// http://linux.die.net/man/3/ssl_ctx_set_verify_depth
/*
static int max_verify_callbacks = 10;
static int n_verify_callbacks = 0;
static int verify_callback(int preverify_ok, X509_STORE_CTX *ctx) {
	printf( "cb %i\n", preverify_ok );
	return preverify_ok;
}
*/
static value hxssl_SSL_CTX_set_verify( value ctx ) {
	SSL_CTX* _ctx = (SSL_CTX*) val_data(ctx);
	//SSL_CTX_set_verify_depth( _ctx, val_int(depth) );
	//SSL_CTX_set_verify_depth( _ctx, 1 );
	SSL_CTX_set_verify( _ctx, SSL_VERIFY_PEER, NULL );
	//SSL_CTX_set_verify( _ctx, SSL_VERIFY_PEER, verify_callback );
	return VAL_NULL;
}

DEFINE_PRIM( hxssl_SSL_library_init, 0 );
DEFINE_PRIM( hxssl_SSL_load_error_strings, 0 );
DEFINE_PRIM( hxssl_SSL_new, 1 );
DEFINE_PRIM( hxssl_SSL_close, 1 );
DEFINE_PRIM( hxssl_SSL_set_bio, 3 );
DEFINE_PRIM( hxssl_SSL_connect, 1 );
DEFINE_PRIM( hxssl_SSL_shutdown, 1 );
DEFINE_PRIM( hxssl_SSL_free, 1 );
DEFINE_PRIM( hxssl_SSLv23_client_method, 0 );
DEFINE_PRIM( hxssl_TLSv1_client_method, 0 );
DEFINE_PRIM( hxssl_SSL_CTX_new, 1 );
DEFINE_PRIM( hxssl_SSL_CTX_close, 1 );
DEFINE_PRIM( hxssl_SSL_send, 4 );
DEFINE_PRIM( hxssl_SSL_send_char, 2 );
DEFINE_PRIM( hxssl_SSL_recv, 4 );
DEFINE_PRIM( hxssl_SSL_recv_char, 1 );
DEFINE_PRIM( hxssl_BIO_NOCLOSE, 0 );
DEFINE_PRIM( hxssl_BIO_new_socket, 2 );
DEFINE_PRIM( hxssl___SSL_read, 1 );
DEFINE_PRIM( hxssl___SSL_write, 2 );
DEFINE_PRIM( hxssl_SSL_CTX_load_verify_locations, 3 );
DEFINE_PRIM( hxssl_SSL_CTX_set_verify, 1 );
