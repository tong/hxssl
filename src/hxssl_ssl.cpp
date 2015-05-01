
#define IMPLEMENT_API
#define NEKO_COMPATIBLE

#include <hx/CFFI.h>
#include <stdio.h>
#include <string.h>

#if !_MSC_VER
#include <sys/socket.h>
#endif

#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/ssl.h>
#include <openssl/x509v3.h>

#ifdef _MSC_VER 
#define strcasecmp _stricmp
#define strncasecmp _strnicmp
#endif

#if !_MSC_VER
typedef int SOCKET;
#endif

#define SOCKET_ERROR (-1)
#define NRETRYS	20

#define val_ssl(o)	(SSL*)val_data(o)
#define val_ctx(o)	(SSL_CTX*)val_data(o)
//#define val_sock(o)	(SSL_CTX*)val_data(o)

DEFINE_KIND( k_ssl_method_pointer );
DEFINE_KIND( k_ssl_ctx_pointer );
DEFINE_KIND( k_ssl_ctx );
DEFINE_KIND( k_BIO );

#if !_MSC_VER
typedef struct {
	//SOCKET sock;
	SSL *ssl;
	char *buf;
	int size;
	int ret;
} sock_tmp;
#endif

typedef enum {
	MatchFound,
	MatchNotFound,
	NoSANPresent,
	MalformedCertificate,
	Error
} HostnameValidationResult;

static value block_error() {
	#ifdef NEKO_WINDOWS
	int err = WSAGetLastError();
	if( err == WSAEWOULDBLOCK || err == WSAEALREADY || err == WSAETIMEDOUT )
	#else
	if( errno == EAGAIN || errno == EWOULDBLOCK || errno == EINPROGRESS || errno == EALREADY )
	#endif
		val_throw(alloc_string("Blocking"));
	neko_error();
	return alloc_null();
}

static value hxssl_SSL_library_init() {
	SSL_library_init();
	//OpenSSL_add_all_algorithms(); // required ?
	return alloc_null();
}

static value hxssl_SSL_load_error_strings() {
	SSL_load_error_strings();
	return alloc_null();
}

static value hxssl_SSL_new( value ctx ) {
	SSL* ssl = SSL_new( val_ctx(ctx) );
	if( ssl == NULL )
		neko_error();
	return alloc_abstract( k_ssl_ctx, ssl );
}

static value hxssl_SSL_close( value ssl ) {
	SSL_free( val_ssl(ssl) );
	return alloc_null();
}

static value hxssl_SSL_connect( value ssl ) {
	int r = SSL_connect( val_ssl(ssl) );
	if( r < 0 )
		neko_error();
	return alloc_int( r );
}

static value hxssl_SSL_shutdown( value ssl ) {
	return alloc_int( SSL_shutdown( val_ssl(ssl) ) );
}

static value hxssl_SSL_free( value ssl ) {
	SSL_free( val_ssl(ssl) );
	return alloc_null();
}

static value hxssl_SSL_set_bio( value ssl, value rbio, value wbio ) {
	SSL_set_bio( val_ssl(ssl), (BIO*) val_data(rbio), (BIO*) val_data(wbio) );
	return alloc_null();
}

static value hxssl_SSLv23_client_method() {
	return alloc_abstract( k_ssl_method_pointer, (SSL_METHOD*)SSLv23_client_method() );
}
static value hxssl_TLSv1_client_method() {
	return alloc_abstract( k_ssl_method_pointer, (SSL_METHOD*)TLSv1_client_method() );
}

static value hxssl_SSLv23_server_method() {
    return alloc_abstract( k_ssl_method_pointer, (SSL_METHOD*)SSLv23_server_method() );
}
static value hxssl_TLSv1_server_method() {
	return alloc_abstract( k_ssl_method_pointer, (SSL_METHOD*)TLSv1_server_method() );
}

static value hxssl_SSL_CTX_new( value m ) {
	SSL_CTX * ctx = SSL_CTX_new( (SSL_METHOD*) val_data(m) );
	return alloc_abstract( k_ssl_ctx_pointer, ctx );
}
static value hxssl_SSL_CTX_close( value ctx ) {
	SSL_CTX_free( val_ctx(ctx) );
	return alloc_null();
}

static value hxssl_SSL_CTX_load_verify_locations( value ctx, value certFile, value certFolder ) {
        const char *sslCertFile;
        const char *sslCertFolder;
        int r;
        if( val_is_string( certFile ) && val_is_string( certFolder ) ) {
                sslCertFile = val_string( certFile );
                sslCertFolder = val_string( certFolder );
                r = SSL_CTX_load_verify_locations( val_ctx(ctx), sslCertFile, sslCertFolder );
        } else {
                r = SSL_CTX_set_default_verify_paths( val_ctx(ctx) );
        }
        //printf( "SSL cert file: %s\n", sslCertFile );
        //printf( "SSL cert folder: %s\n", sslCertFolder );
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

// HostnameValidation based on https://github.com/iSECPartners/ssl-conservatory
// Wildcard cmp based on libcurl hostcheck
static HostnameValidationResult hxssl_match_hostname( const ASN1_STRING *asn1, const char *hostname ){	
	char *pattern, *wildcard, *pattern_end, *hostname_end;
	int prefixlen, suffixlen;
	if( asn1 == NULL )
		return Error;

	pattern = (char *)ASN1_STRING_data((ASN1_STRING *)asn1);
	
	if( ASN1_STRING_length((ASN1_STRING *)asn1) != strlen(pattern) ){
		return MalformedCertificate;
	}else{
		wildcard = strchr(pattern, '*');
		if( wildcard == NULL ){
			if( strcasecmp(pattern, hostname) == 0 )
				return MatchFound;
			return MatchNotFound;
		}
		pattern_end = strchr(pattern, '.');	
		if( pattern_end == NULL || strchr(pattern_end+1,'.') == NULL || wildcard > pattern_end || strncasecmp(pattern,"xn--",4)==0 )
			return MatchNotFound;
		hostname_end = strchr((char *)hostname, '.');
		if( hostname_end == NULL || strcasecmp(pattern_end, hostname_end) != 0 )
			return MatchNotFound;
		if( hostname_end-hostname < pattern_end-pattern )
			return MatchNotFound;

		prefixlen = wildcard - pattern;
		suffixlen = pattern_end - (wildcard+1);
		if( strncasecmp(pattern, hostname, prefixlen) != 0 )
			return MatchNotFound;
		if( strncasecmp(pattern_end-suffixlen, hostname_end-suffixlen, suffixlen) != 0 )
			return MatchNotFound;

		return MatchFound;
	}
	return MatchNotFound;
}

static HostnameValidationResult hxssl_matches_subject_alternative_name( const X509 *server_cert, const char *hostname ){
	int i;
	int nb = -1;
	HostnameValidationResult r;
	STACK_OF(GENERAL_NAME) *san_names = NULL;

	san_names = (STACK_OF(GENERAL_NAME) *) X509_get_ext_d2i((X509 *)server_cert, NID_subject_alt_name, NULL, NULL);
	if( san_names == NULL )
		return NoSANPresent;
	nb = sk_GENERAL_NAME_num(san_names);

	for( i=0; i<nb; i++ ){
		const GENERAL_NAME *cur = sk_GENERAL_NAME_value(san_names, i);
		if( cur->type == GEN_DNS ){
			r = hxssl_match_hostname( cur->d.dNSName, hostname );
			if( r != MatchNotFound )
				return r;
		}
	}
	sk_GENERAL_NAME_pop_free(san_names, GENERAL_NAME_free);
	return MatchNotFound;
}

static HostnameValidationResult hxssl_matches_common_name(const X509 *server_cert, const char *hostname ){
	int cn_loc = -1;
	X509_NAME_ENTRY *cn_entry = NULL;

	
	cn_loc = X509_NAME_get_index_by_NID(X509_get_subject_name((X509 *)server_cert), NID_commonName, -1);
	if( cn_loc < 0 )
		return Error;

	cn_entry = X509_NAME_get_entry(X509_get_subject_name((X509 *)server_cert), cn_loc);
	if( cn_entry == NULL )
		return Error;

	return hxssl_match_hostname(X509_NAME_ENTRY_get_data(cn_entry), hostname);
}

static value hxssl_validate_hostname( value ssl, value hostname ){
	val_check(hostname,string);
	const char *name = val_string(hostname);
	X509 *server_cert = SSL_get_peer_certificate(val_ssl(ssl));
	HostnameValidationResult result;

	if( server_cert == NULL )
		neko_error();

	result = hxssl_matches_subject_alternative_name(server_cert, name);
	if (result == NoSANPresent) 
		result = hxssl_matches_common_name(server_cert, name);
	
	if( result == MatchFound )
		return alloc_null();

	switch( result ){
		case MatchNotFound:
			val_throw(alloc_string("MatchNotFound"));
			break;
		case MalformedCertificate:
			val_throw(alloc_string("MalformedCertificate"));
			break;
	}

	neko_error();
	return alloc_null();
}

static value hxssl_SSL_set_tlsext_host_name( value ssl, value hostname ){
	val_check(hostname,string);
	if( !SSL_set_tlsext_host_name( val_ssl(ssl), val_string(hostname) ) )
		neko_error();
	return alloc_null();
}

static value hxssl_SSL_CTX_set_verify( value ctx ) {
	SSL_CTX* _ctx = val_ctx(ctx);
	//SSL_CTX_set_verify_depth( _ctx, val_int(depth) );
	//SSL_CTX_set_verify_depth( _ctx, 1 );
	SSL_CTX_set_verify( _ctx, SSL_VERIFY_PEER, NULL );
	//SSL_CTX_set_verify( _ctx, SSL_VERIFY_PEER, verify_callback );
	return alloc_null();
}

static value hxssl_SSL_CTX_use_certificate_file( value ctx, value certFile, value privateKeyFile ) {
	SSL_CTX* _ctx = val_ctx(ctx);
	SSL_CTX_use_certificate_chain_file( _ctx, val_string(certFile) );
	SSL_CTX_use_PrivateKey_file( _ctx, val_string(privateKeyFile), SSL_FILETYPE_PEM );
	if( !SSL_CTX_check_private_key(_ctx) ) {
 		neko_error();
	}
	return alloc_null();
}

static value hxssl_SSL_CTX_set_session_id_context( value ctx, value sid ) {
	val_check(sid,string);

	SSL_CTX *_ctx = val_ctx(ctx);
	const char *_sid = val_string(sid);

	if( SSL_CTX_set_session_id_context(_ctx, (unsigned char *)_sid, sizeof _sid) != 1 )
		neko_error();

    return alloc_null();
}

static int hxssl_ssl_servername_cb(SSL *ssl, int *ad, void *arg){
	AutoGCRoot *p = (AutoGCRoot *)arg;
	const char *servername = SSL_get_servername(ssl, TLSEXT_NAMETYPE_host_name);
	
	if( servername && p != 0 ){
	 	value ret = val_call1(p->get(), alloc_string(servername)) ;
		if( !val_is_null(ret) )
			SSL_set_SSL_CTX( ssl, val_ctx(ret) );
	}
	
	return SSL_TLSEXT_ERR_OK;
}

static value hxssl_SSL_set_tlsext_servername_callback( value ctx, value cb ){
	SSL_CTX *_ctx = val_ctx(ctx);
	AutoGCRoot *arg = new AutoGCRoot(cb);

	SSL_CTX_set_tlsext_servername_callback( _ctx, hxssl_ssl_servername_cb );
	SSL_CTX_set_tlsext_servername_arg( _ctx, (void *)arg );
	return alloc_null();
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
	if( dlen < 0 )
		neko_error();
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
	return alloc_null();
}

// keep for compat
static value hxssl___SSL_accept( value n ) {
	neko_error();
	return alloc_null();
}

static value hxssl_SSL_accept( value ssl, value sock ) {
	SSL* _ssl = val_ssl( ssl );
	if( _ssl == NULL )
		neko_error();
	int _sock = ((int_val) val_data(sock) );
	if( !SSL_set_fd( _ssl, _sock ) )
	    neko_error();
	if( SSL_accept( _ssl ) < 0 )
	    neko_error();
	return alloc_null();
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
DEFINE_PRIM( hxssl_SSLv23_server_method, 0 );
DEFINE_PRIM( hxssl_TLSv1_server_method, 0 );

DEFINE_PRIM( hxssl_SSL_CTX_new, 1 );
DEFINE_PRIM( hxssl_SSL_CTX_close, 1 );
DEFINE_PRIM( hxssl_SSL_CTX_load_verify_locations, 3 );
DEFINE_PRIM( hxssl_SSL_CTX_set_verify, 1 );
DEFINE_PRIM( hxssl_SSL_CTX_use_certificate_file, 3 );
DEFINE_PRIM( hxssl_SSL_CTX_set_session_id_context, 2 );
DEFINE_PRIM( hxssl_validate_hostname, 2 );
DEFINE_PRIM( hxssl_SSL_set_tlsext_host_name, 2 );
DEFINE_PRIM( hxssl_SSL_set_tlsext_servername_callback, 2 );

DEFINE_PRIM( hxssl_BIO_NOCLOSE, 0 );
DEFINE_PRIM( hxssl_BIO_new_socket, 2 );

DEFINE_PRIM( hxssl_SSL_send, 4 );
DEFINE_PRIM( hxssl_SSL_send_char, 2 );
DEFINE_PRIM( hxssl_SSL_recv, 4 );
DEFINE_PRIM( hxssl_SSL_recv_char, 1 );

DEFINE_PRIM( hxssl___SSL_read, 1 );
DEFINE_PRIM( hxssl___SSL_write, 2 );

DEFINE_PRIM( hxssl___SSL_accept, 1 );
DEFINE_PRIM( hxssl_SSL_accept, 2 );
