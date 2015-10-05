package sys.ssl;

#if php
import php.net.SslSocket in Socket;
#elseif cs
typedef Socket = sys.net.Socket; //TODO
#elseif java
typedef Socket = sys.net.Socket; //TODO
#else
import sys.net.Host;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.Error;
import haxe.io.Eof;
#if cpp
import cpp.Lib;
#elseif neko
import neko.Lib;
#end

private typedef SocketHandle = Dynamic;
private typedef CTX = Dynamic;
private typedef SSL = Dynamic;

private class SocketInput extends haxe.io.Input {

	@:allow(sys.ssl.Socket) private var __s : SocketHandle;
	@:allow(sys.ssl.Socket) private var ssl : SSL;

	public function new( s : SocketHandle, ?ssl : SSL ) {
		this.__s = s;
		this.ssl = ssl;
	}

	public override function readByte() {
		return try {
			socket_recv_char( ssl );
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw Blocked;
			else if( __s == null )
				throw Custom(e);
			else
				throw new Eof();
		}
	}

	public override function readBytes( buf : Bytes, pos : Int, len : Int ) : Int {
		var r : Int;
		if( ssl == null || __s == null )
			throw "Invalid handle";
		try {
			r = socket_recv(  ssl, buf.getData(), pos, len );
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw Blocked;
			else
				throw Custom(e);
		}
		if( r == 0 )
			throw new Eof();
		return r;
	}

	public override function close() {
		super.close();
		if( __s != null ) socket_close( __s );
	}

	private static var socket_recv = Socket.load( "SSL_recv", 4 );
	private static var socket_recv_char = Socket.load( "SSL_recv_char", 1 );
	private static var socket_close = Lib.load( "std", "socket_close", 1 );

}

private class SocketOutput extends haxe.io.Output {

	@:allow(sys.ssl.Socket) private var __s : SocketHandle;
	@:allow(sys.ssl.Socket) private var ssl : SSL;

	public function new(s) {
		__s = s;
	}

	public override function writeByte( c : Int ) {
		if( __s == null )
			throw "Invalid handle";
		try {
			socket_send_char( ssl, c);
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw Blocked;
			else
				throw Custom(e);
		}
	}

	public override function writeBytes( buf : Bytes, pos : Int, len : Int) : Int {
		return try {
			socket_send( ssl, buf.getData(), pos, len);
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw Blocked;
			else
				throw Custom(e);
		}
	}

	public override function close() {
		super.close();
		if( __s != null ) socket_close(__s);
	}

	private static var socket_close = Lib.load( "std", "socket_close", 1 );
	private static var socket_send_char = Socket.load( "SSL_send_char", 2 );
	private static var socket_send = Socket.load( "SSL_send", 4 );

}


/**
	Secure socket
*/
class Socket {

	/**
		Socket input stream.
	**/
	public var input(default,null) : SocketInput;
	
	/**
		Socket output stream.
	**/
	public var output(default,null) : SocketOutput;
	
	/**
		If true then client socket will validate server sent certificate. Defaults to true.
	**/
	public var validateCert : Bool;
	
	private var __s : Dynamic;
	private var ctx : CTX;
	private var ssl : SSL;

	private var verifyCertFile : String;
	private var verifyCertFolder : String;
	private var verifyHostname : String;

	private var useCertChainFile : String;
	private var useKeyFile : String;
	private var altSNIContexts : Null<Array<{match: String->Bool, ctx: CTX}>>;
	
	/**
		Create a new SSL socket object.
		
		Socket can be run in either client or server mode.
	**/
	public function new() {
		//connected = secure = false;
		initSSL();
		__s = socket_new( false );
		input = new SocketInput( __s );
		output = new SocketOutput( __s );
		validateCert = true;
	}
	
	/**
		Initiate a connection to a remote host.
	**/
	public function connect(host : Host, port : Int) : Void {
		try {
			if( verifyHostname == null )
				verifyHostname = host.host;
			socket_connect( __s, host.ip, port );
			ctx = buildSSLContext( false );
			ssl = SSL_new( ctx );
			input.ssl = ssl;
			output.ssl = ssl;
			var sbio = BIO_new_socket( __s, BIO_NOCLOSE() );
			SSL_set_bio( ssl, sbio, sbio );
			if( validateCert )
				SSL_set_tlsext_host_name( ssl, verifyHostname );
			var r : Int = SSL_connect( ssl );
			if( validateCert )
				validate_hostname( ssl, verifyHostname );
		} catch( s : String ) {
			if( s == "std@socket_connect" )
				throw "Failed to connect on "+(try host.reverse() catch(e:Dynamic) host.toString())+":"+port;
			else
				Lib.rethrow(s);
		} catch( e : Dynamic ) {
			Lib.rethrow(e);
		}
	}

	/**
		Set custom paths to cert locations.
		
		This should only be used if you know what you are doing.
		By default certficate locations are automatically detected.
		
		Client mode only.
	**/
	public function setCertLocation( file : String, folder : String ) {
		verifyCertFile = file;
		verifyCertFolder = folder;
	}
	
	public function setHostname( hostname : String ){
		verifyHostname = hostname;
	}
	
	/**
		Set certificate and private key locations.
		
		Both the certificate and private key should be in PEM format.
		
		The certificate should contain both the certificate itself as well as the rest of the chain.
		
		Server mode only.
	**/
	public function useCertificate( certChainFile : String, keyFile : String ){
		useCertChainFile = certChainFile;
		useKeyFile = keyFile;
	}

	//TODO
	//public function setSecure() {}
	
	/**
		Read the whole data available on the socket.
	**/
	public function read() : String {
		var b = socket_read( ssl );
		if( b == null )
			return "";
		return b.toString();
	}
	
	/**
		Write the whole data to the socket output.
	**/
	public function write( content : String ) {
		socket_write( ssl, content );
	}
	
	/**
		Closes the socket : make sure to properly close all your sockets or you will crash when you run out of file descriptors.
	**/
	public function close() : Void {
//		SSL_shutdown( ssl );
		SSL_close( ssl );
		SSL_CTX_close( ctx );
		if( altSNIContexts != null ){
			for( c in altSNIContexts )
				SSL_CTX_close( c.ctx );
		}
		//SSL_free( ssl ); 
		socket_close( __s );
		input.__s = output.__s = null;
		input.ssl = output.ssl = null;
		input.close();
		output.close();
	}
	
	/**
		Add a certificate, private key for the given server name.
		
		Only works for SNI-enabled clients.
		
		Server mode only.
	**/
	public function addSNICertificate( cbServernameMatch : String->Bool, certChainFile : String, keyFile : String ) : Void{
		if( altSNIContexts == null )
			altSNIContexts = [];

		var nctx = SSL_CTX_new( SSLv23_server_method() );
		SSL_CTX_use_certificate_file( nctx, untyped certChainFile.__s, untyped keyFile.__s );
		altSNIContexts.push( {match: cbServernameMatch, ctx: nctx} );
	}
	
	/**
		Bind the socket to the given host/port so it can afterwards listen for connections there.
	**/
	public function bind( host : Host, port : Int ) : Void {
		ctx = buildSSLContext( true );

		SSL_CTX_set_session_id_context( ctx, haxe.crypto.Md5.make(haxe.io.Bytes.ofString(host.toString()+":"+port)).getData() );
		socket_bind( __s, host.ip, port );
	}
	
	/**
		Allow the socket to listen for incoming questions. The parameter tells how many pending connections we can have until they get refused. Use [accept()] to accept incoming connections.
	**/
	public function listen( connections : Int ) : Void {
		socket_listen( __s, connections );
	}
	
	/**
		Accept a new connected client. This will return a connected socket on which you can read/write some data.
	**/
	public function accept() : Socket {
		var c = socket_accept( __s );
		var ssl = SSL_new( ctx );

		var s = Type.createEmptyInstance( sys.ssl.Socket );
		s.__s = c;
		s.ssl = ssl;
		s.input = new SocketInput(c);
		s.input.ssl = ssl;
		s.output = new SocketOutput(c);
		s.output.ssl = ssl;

		SSL_accept( ssl, c );

		return s;
	}
	
	/**
		Return the informations about the other side of a connected socket.
	**/
	public function peer() : { host : Host, port : Int } {
		var a : Dynamic = socket_peer(__s);
		var h = new Host("127.0.0.1");
		untyped h.ip = a[0];
		return { host : h, port : a[1] };
	}
	
	/**
		Shutdown the socket, either for reading or writing.
	**/
	public function shutdown( read : Bool, write : Bool ) : Void {
		SSL_shutdown( ssl );
		socket_shutdown( __s, read, write );
	}
	
	/**
		Return the informations about our side of a connected socket.
	**/
	public function host() : { host : Host, port : Int } {
		var a : Dynamic = socket_host( __s );
		var h = new Host( "127.0.0.1" );
		untyped h.ip = a[0];
		return { host : h, port : a[1] };
	}
	
	/**
		Gives a timeout after which blocking socket operations (such as reading and writing) will abort and throw an exception.
	**/
	public function setTimeout( timeout : Float ) : Void {
		socket_set_timeout( __s, timeout );
	}
	
	/**
		Block until some data is available for read on the socket.
	**/
	public function waitForRead() : Void {
		select([this],null,null,null);
	}
	
	/**
		Change the blocking mode of the socket. A blocking socket is the default behavior. A non-blocking socket will abort blocking operations immediatly by throwing a haxe.io.Error.Blocking value.
	**/
	public function setBlocking( b : Bool ) : Void {
		socket_set_blocking(__s,b);
	}
	
	/**
		Allows the socket to immediatly send the data when written to its output : this will cause less ping but might increase the number of packets / data size, especially when doing a lot of small writes.
	**/
	public function setFastSend( b : Bool ) : Void {
		socket_set_fast_send(__s,b);
	}

	private function initSSL() {
		SSL_library_init();
		SSL_load_error_strings();
	}

	private function buildSSLContext( server : Bool ) : CTX {
		var ctx : CTX = SSL_CTX_new( server ? SSLv23_server_method() : SSLv23_client_method() );
		if( validateCert ) {
			var r : Int = SSL_CTX_load_verify_locations( ctx, verifyCertFile, verifyCertFolder );
			if( r == 0 )
				throw "Failed to load certificates";
			SSL_CTX_set_verify( ctx );
		}
		if( useCertChainFile != null && useKeyFile != null ){
			var r : Int = SSL_CTX_use_certificate_file( ctx, useCertChainFile, useKeyFile );
			if( r == 0 )
				throw "Failed to use certificate";
		}
		if( altSNIContexts != null ){
			SSL_set_tlsext_servername_callback( ctx, function(servername){
				for( c in altSNIContexts ){
					if( c.match(servername) )
						return c.ctx;
				}
				return null;
			});
		}
		return ctx;
	}
	
	/**
		Wait until one of the sockets groups is ready for the given operation :
		[read] contains sockets on which we want to wait for available data to be read,
		[write] contains sockets on which we want to wait until we are allowed to write some data to their output buffers,
		[others] contains sockets on which we want to wait for exceptional conditions.
		[select] will block until one of the condition is met, in which case it will return the sockets for which the condition was true.
		In case a [timeout] (in seconds) is specified, select might wait at worse until the timeout expires.
	**/
	public static function select( read : Array<Socket>, write : Array<Socket>, others : Array<Socket>, ?timeout : Float ) : { read: Array<Socket>, write: Array<Socket>, others: Array<Socket> } {
		var neko_array = socket_select( read, write, others, timeout );
		if( neko_array == null )
			throw "Select error";
		return {
			read: neko_array[0],
			write: neko_array[1],
			others: neko_array[2]
		};
	}

	private static var SSL_library_init = load( "SSL_library_init" );
	private static var SSL_load_error_strings = load( "SSL_load_error_strings" );

	private static var SSL_new = load( "SSL_new", 1 );
	private static var SSL_close = load( "SSL_close", 1 );
	private static var SSL_connect = load( "SSL_connect", 1 );
	private static var SSL_shutdown = load( "SSL_shutdown", 1 );
	private static var SSL_free = load( "SSL_free", 1 );

	private static var SSL_set_bio = load( "SSL_set_bio", 3 );
	
	private static var SSLv23_client_method = load( 'SSLv23_client_method' );
	private static var SSLv23_server_method = load( 'SSLv23_server_method' );

	private static var validate_hostname = load( 'validate_hostname', 2 );
	private static var SSL_set_tlsext_host_name = load( "SSL_set_tlsext_host_name", 2 );
	private static var SSL_set_tlsext_servername_callback = load( "SSL_set_tlsext_servername_callback", 2 );
	
	private static var SSL_CTX_new = load( 'SSL_CTX_new', 1 );
	private static var SSL_CTX_close = load( 'SSL_CTX_close', 1 );
	private static var SSL_CTX_load_verify_locations = load( 'SSL_CTX_load_verify_locations', 3 );
	private static var SSL_CTX_set_verify = load( 'SSL_CTX_set_verify', 1 );
	private static var SSL_CTX_use_certificate_file = load( 'SSL_CTX_use_certificate_file', 3 );
	private static var SSL_CTX_set_session_id_context = load( 'SSL_CTX_set_session_id_context', 2 );
	
	private static var BIO_new_socket = load( "BIO_new_socket", 2 );
	private static var BIO_NOCLOSE = load( "BIO_NOCLOSE", 0 );
	
	private static var socket_read = load( '__SSL_read', 1 );
	private static var socket_write = load( '__SSL_write', 2 );
	//private static var socket_listen = lib( '__SSL_listen', 3 );
	private static var SSL_accept = load( 'SSL_accept', 2 );
	
	@:allow(sys.ssl)
	private static function load( f : String, args : Int = 0 ) : Dynamic {
		#if neko
		if( !moduleInit ) loadNekoAPI();
		#end
		return Lib.load( 'hxssl', 'hxssl_'+f, args );
	}

	#if neko
	private static var moduleInit = false;
	private static function loadNekoAPI() {
		var init = Lib.load( 'hxssl', 'neko_init', 5 );
		if( init != null ) {
			init(function(s) return new String(s), function(len:Int) { var r = []; if (len > 0) r[len - 1] = null; return r; }, null, true, false);
			moduleInit = true;
		} else
			throw 'Could not find nekoapi interface';
	}
	#end

	private static var socket_new = Lib.load("std","socket_new",1);
	private static var socket_close = Lib.load("std","socket_close",1);
	private static var socket_connect = Lib.load("std","socket_connect",3);
	private static var socket_listen = Lib.load("std","socket_listen",2);
	private static var socket_select = Lib.load("std","socket_select",4);
	private static var socket_bind = Lib.load("std","socket_bind",3);
	private static var socket_accept = Lib.load("std","socket_accept",1);
	private static var socket_peer = Lib.load("std","socket_peer",1);
	private static var socket_host = Lib.load("std","socket_host",1);
	private static var socket_set_timeout = Lib.load("std","socket_set_timeout",2);
	private static var socket_shutdown = Lib.load("std","socket_shutdown",3);
	private static var socket_set_blocking = Lib.load("std","socket_set_blocking",2);
	private static var socket_set_fast_send = Lib.loadLazy("std","socket_set_fast_send",2);

}

#end
