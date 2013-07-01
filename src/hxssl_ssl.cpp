
#define IMPLEMENT_API
#define NEKO_COMPATIBLE

#include <hx/CFFI.h>
#include <stdio.h>
#include <sys/socket.h>
#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/ssl.h>



typedef int SOCKET;

#define SOCKET_ERROR (-1)
#define val_ssl(o)	(SSL*)val_data(o)
#define val_ctx(o)	(SSL_CTX*)val_data(o)
#define VAL_NULL    alloc_int(0) // TODO neko error on val_null ???

#define NRETRYS	20

DEFINE_KIND( k_ssl_method_pointer);
DEFINE_KIND( k_ssl_ctx_pointer );
DEFINE_KIND( k_ssl_ctx );
DEFINE_KIND( k_BIO );

typedef struct {
	//SOCKET sock;
	SSL *ssl;
	char *buf;
	int size;
	int ret;
} sock_tmp;


static value block_error() {
	#ifdef NEKO_WINDOWS
	int err = WSAGetLastError();
	if( err == WSAEWOULDBLOCK || err == WSAEALREADY || err == WSAETIMEDOUT )
	#else
	if( errno == EAGAIN || errno == EWOULDBLOCK || errno == EINPROGRESS || errno == EALREADY )
	#endif
		val_throw(alloc_string("Blocking"));
	neko_error();
	return val_true;
}



static value hxssl_SSL_library_init() {
	SSL_library_init();
	//OpenSSL_add_all_algorithms(); // required ?
	return VAL_NULL;
}

static value hxssl_SSL_load_error_strings() {
	SSL_load_error_strings();
	return VAL_NULL;
}


static value hxssl_SSL_new( value ctx ) {
	SSL* ssl = SSL_new( val_ctx(ctx) );
	return alloc_abstract( k_ssl_ctx, ssl );
}

static value hxssl_SSL_close( value ssl ) {
	SSL_free( val_ssl(ssl) );
	return VAL_NULL;
}

static value hxssl_SSL_connect( value ssl ) {
	int r = SSL_connect( val_ssl(ssl) );
	return alloc_int( r );
}

static value hxssl_SSL_shutdown( value ssl ) {
	return alloc_int( SSL_shutdown( val_ssl(ssl) ) );
}

static value hxssl_SSL_free( value ssl ) {
	SSL_free( val_ssl(ssl) );
	return VAL_NULL;
}


static value hxssl_SSL_set_bio( value ssl, value rbio, value wbio ) {
	SSL_set_bio( val_ssl(ssl), (BIO*) val_data(rbio), (BIO*) val_data(wbio) );
	return VAL_NULL;
}


static value hxssl_SSLv23_client_method() {
	return alloc_abstract( k_ssl_method_pointer, (SSL_METHOD*)SSLv23_client_method() );
}
static value hxssl_TLSv1_client_method() {
	return alloc_abstract( k_ssl_method_pointer, (SSL_METHOD*)TLSv1_client_method() );
}


static value hxssl_SSL_CTX_new( value m ) {
	SSL_CTX * ctx = SSL_CTX_new( (SSL_METHOD*) val_data(m) );
	return alloc_abstract( k_ssl_ctx_pointer, ctx );
}
static value hxssl_SSL_CTX_close( value ctx ) {
	SSL_CTX_free( val_ctx(ctx) );
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
	int r = SSL_CTX_load_verify_locations( val_ctx(ctx), sslCertFile, sslCertFolder );
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
	SSL_CTX* _ctx = val_ctx(ctx);
	//SSL_CTX_set_verify_depth( _ctx, val_int(depth) );
	//SSL_CTX_set_verify_depth( _ctx, 1 );
	SSL_CTX_set_verify( _ctx, SSL_VERIFY_PEER, NULL );
	//SSL_CTX_set_verify( _ctx, SSL_VERIFY_PEER, verify_callback );
	return VAL_NULL;
}

static value hxssl_SSL_CTX_use_certificate_file( value ctx, value certFile, value privateKeyFile ) {
	printf("hxssl_SSL_CTX_use_certificate_file\n");
	SSL_CTX* _ctx = val_ctx(ctx);
	SSL_CTX_use_certificate_file( _ctx, val_string(certFile), SSL_FILETYPE_PEM );
	SSL_CTX_use_PrivateKey_file( _ctx, val_string(privateKeyFile), SSL_FILETYPE_PEM );
	if( !SSL_CTX_check_private_key(_ctx) ) {
 		neko_error();
	}
	return VAL_NULL;
}


static value hxssl_BIO_NOCLOSE() {
	return alloc_int( BIO_NOCLOSE );
}

static value hxssl_BIO_new_socket( value sock, value close_flag ) {
	int sock_ = ((int_val) val_data(sock) );
	BIO* bio = BIO_new_socket( sock_, val_int(close_flag) );
	return alloc_abstract( k_BIO, bio );
}


static value hxssl_SSL_send_char( value ssl, value v ) {
	int c = val_int(v);
	if( c < 0 || c > 255 )
		neko_error();
	unsigned char cc;
	cc = (unsigned char) c;
	//if( send(val_sock(o),&cc,1,MSG_NOSIGNAL) == SOCKET_ERROR ) return block_error();
	SSL_write( val_ssl(ssl), &cc, 1 );
	return val_true;
}

static value hxssl_SSL_send( value ssl, value data, value pos, value len ) {
	int p,l,dlen;
	p = val_int(pos);
	l = val_int(len);
	dlen = val_strlen(data);
	if( p < 0 || l < 0 || p > dlen || p + l > dlen )
		neko_error();
	POSIX_LABEL(send_again);
	//dlen = send(val_sock(o), val_string(data) + p , l, MSG_NOSIGNAL);
	dlen = SSL_write( val_ssl(ssl), val_string(data) + p, l );
	if( dlen == SOCKET_ERROR ) {
		HANDLE_EINTR(send_again);
		return block_error();
	}
	return alloc_int(dlen);
}

static value hxssl_SSL_recv( value ssl, value data, value pos, value len ) {

	//TODO
	int p = val_int( pos );
	int l = val_int( len );
	//dlen = val_strlen(data);
	//printf("hxssl_SSL_recv %i %i\n", p, l );
	void * buf = (void *) (val_string(data) + p);
	int dlen = SSL_read( val_ssl(ssl), buf, l );
	//if( p < 0 || l < 0 || p > dlen || p + l > dlen )
	//	neko_error();
	if( dlen == 0 ) {
		//int err = SSL_get_error( _ssl, dlen );
		neko_error();
	}
	//if( dlen == SOCKET_ERROR )
	return alloc_int( dlen );

	/*
	int p,l,dlen,ret;
	int retry = 0;
	//val_check_kind(o,k_socket);
	//val_check(data,string);
	//val_check(pos,int);
	//val_check(len,int);
	p = val_int(pos);
	l = val_int(len);
	dlen = val_strlen(data);
	if( p < 0 || l < 0 || p > dlen || p + l > dlen )
		neko_error();
	POSIX_LABEL(recv_again);
	if( retry++ > NRETRYS ) {
		sock_tmp t;
		//t.sock = val_sock(o);
		t.ssl = val_ssl(ssl);
		t.buf = val_string(data) + p;
		t.size = l;
		neko_thread_blocking(tmp_recv,&t);
		ret = t.ret;
	} else
		ret = SSL_read( val_ssl(ssl), buf, l );
		//ret = recv(val_sock(o), val_string(data) + p , l, MSG_NOSIGNAL);
	if( ret == SOCKET_ERROR ) {
		HANDLE_EINTR(recv_again);
		return block_error();
	}
	return alloc_int(ret);
	*/
}

static value hxssl_SSL_recv_char(value ssl) {
	unsigned char c;
	int r = SSL_read( val_ssl(ssl), &c, 1 );
	if( r <= 0 )
		neko_error();
	return alloc_int( c );
}


static  value hxssl___SSL_read( value ssl ) {
	
	/*
	buffer b;
	int bufsize = 256; //TODO buffer size
	int len;
	char buf[bufsize];
	b = alloc_buffer(NULL);
	SSL* _ssl = val_ssl(ssl);
	while( true ) {
		len = SSL_read( _ssl, buf, bufsize );
		//if( len == SOCKET_ERROR )
		//	return block_error();
		if( len == 0 )
			break;
		buffer_append_sub( b, buf, len );
	}
	return buffer_to_string(b);
	*/
	
	int bufsize = 256;
	buffer b;
	char buf[256];
	int len;
	//val_check_kind( o, k_socket);
	SSL* _ssl = val_ssl(ssl);
	b = alloc_buffer(NULL);
	while( true ) {
		POSIX_LABEL(read_again);
		//len = recv(val_sock(o),buf,256,MSG_NOSIGNAL);
		len = SSL_read( _ssl, buf, bufsize );
		if( len == SOCKET_ERROR ) {
			HANDLE_EINTR(read_again);
			return block_error();
		}
		if( len == 0 )
			break;
		buffer_append_sub(b,buf,len);
	}
	return buffer_to_string(b);
}

static value hxssl___SSL_write( value ssl, value data ) {
	int len, slen;
	const char *s = val_string( data );
	len = val_strlen( data );
	SSL* _ssl = val_ssl(ssl);
	while( len > 0 ) {
		POSIX_LABEL( write_again );
		slen = SSL_write( _ssl, s, len );
		if( slen == SOCKET_ERROR ) {
			HANDLE_EINTR( write_again );
			return block_error();
		}
		s += slen;
		len -= slen;
	}
	return VAL_NULL;
}

/*
static value hxssl___SSL_listen( value socket, value ssl, value connections ) {
	printf("Socket.listen not implemented\n");
	//val_check_kind(o,k_socket);
	//val_check(n,int);
	if( listen(val_sock(socket),val_int(connections)) == SOCKET_ERROR )
		neko_error();
	return val_true;
	//return VAL_NULL;
}
*/

static value hxssl___SSL_accept( value ssl ) {
	//TODO
	SSL* _ssl = val_ssl( ssl );
	SSL_set_accept_state( _ssl );
	int client;
	SSL_set_fd( _ssl, client );
	SSL_accept( _ssl );      
	printf("Socket.accept\n");
	return VAL_NULL;
}



DEFINE_PRIM( hxssl_SSL_library_init, 0 );
DEFINE_PRIM( hxssl_SSL_load_error_strings, 0 );

DEFINE_PRIM( hxssl_SSL_new, 1 );
DEFINE_PRIM( hxssl_SSL_close, 1 );
DEFINE_PRIM( hxssl_SSL_connect, 1 );
DEFINE_PRIM( hxssl_SSL_shutdown, 1 );
DEFINE_PRIM( hxssl_SSL_free, 1 );

DEFINE_PRIM( hxssl_SSL_set_bio, 3 );

DEFINE_PRIM( hxssl_SSLv23_client_method, 0 );
DEFINE_PRIM( hxssl_TLSv1_client_method, 0 );

DEFINE_PRIM( hxssl_SSL_CTX_new, 1 );
DEFINE_PRIM( hxssl_SSL_CTX_close, 1 );
DEFINE_PRIM( hxssl_SSL_CTX_load_verify_locations, 3 );
DEFINE_PRIM( hxssl_SSL_CTX_set_verify, 1 );
DEFINE_PRIM( hxssl_SSL_CTX_use_certificate_file, 3 );

DEFINE_PRIM( hxssl_BIO_NOCLOSE, 0 );
DEFINE_PRIM( hxssl_BIO_new_socket, 2 );

DEFINE_PRIM( hxssl_SSL_send, 4 );
DEFINE_PRIM( hxssl_SSL_send_char, 2 );
DEFINE_PRIM( hxssl_SSL_recv, 4 );
DEFINE_PRIM( hxssl_SSL_recv_char, 1 );

DEFINE_PRIM( hxssl___SSL_read, 1 );
DEFINE_PRIM( hxssl___SSL_write, 2 );

//TODO socket.listen
//DEFINE_PRIM( hxssl___SSL_listen, 3 );
DEFINE_PRIM( hxssl___SSL_accept, 1 );