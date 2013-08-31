package sys.ssl;

#if php
typedef Socket = php.net.SslSocket;

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
		var r;
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

	public var input(default,null) : SocketInput;
	public var output(default,null) : SocketOutput;
	public var custom : Dynamic;
	//public var validateCert : Bool;
	//public var connected : Bool;
	//public var secure : Bool;
	
	private var __s : Dynamic;
	private var ctx : CTX;
	private var ssl : SSL;
	private var certFile : String;
	private var certFolder : String;

	public function new() {
		//connected = secure = false;
		initSSL();
		__s = socket_new( false );
		input = new SocketInput( __s );
		output = new SocketOutput( __s );
	}

	public function connect(host : Host, port : Int) : Void {
		try {
			socket_connect( __s, host.ip, port );
			ctx = buildSSLContext();
			ssl = SSL_new( ctx );
			input.ssl = ssl;
			output.ssl = ssl;
			var sbio = BIO_new_socket( __s, BIO_NOCLOSE() );
			SSL_set_bio( ssl, sbio, sbio );
			var r : Int = SSL_connect( ssl );
			//connected = true;
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
		Set paths to cert locations
	*/
	public function setCertLocation( file : String, folder : String ) {
		certFile = file;
		certFolder = folder;
	}

	//TODO
	//public function setSecure() {}

	public function read() : String {
		trace("read");
		var b = socket_read( ssl );
		if( b == null )
			return "";
		trace("reat");
		return b.toString();
	}

	public function write( content : String ) {
		#if cpp
		socket_write( ssl, content );
		#elseif neko
		socket_write( ssl, untyped content.__s );
		#end
	}

	public function close() : Void {
//		SSL_shutdown( ssl );
		SSL_close( ssl );
		SSL_CTX_close( ctx );
		//SSL_free( ssl ); 
		socket_close( __s );
		input.__s = output.__s = null;
		input.ssl = output.ssl = null;
		input.close();
		output.close();
	}

	/*
	public function bind( host : Host, port : Int ) : Void {
		
		//TODO
		
		trace("bind");
		
		ctx = SSL_CTX_new( SSLv23_client_method() );
		SSL_CTX_use_certificate_file( ctx, "server.crt", "server.key" );
		
		ssl = SSL_new( ctx );
		input.ssl = ssl;
		output.ssl = ssl;
		var bio = BIO_new_socket( __s, BIO_NOCLOSE() );
		SSL_set_bio( ssl, bio, bio );
		socket_bind( __s, host.ip, port );
	}

	public function listen( connections : Int ) : Void {
		socket_listen( __s, connections );
		//socket_listen( __s, ssl, connections );
	}

	public function accept() : Socket {
		trace("accept");
		var c = socket_accept( __s );
		var s = Type.createEmptyInstance( sys.ssl.Socket );
		s.__s = c;
		//s.ssl = ssl;
		ssl_accept( ssl );
		s.input = new SocketInput(c);
		s.input.ssl = ssl;
		s.output = new SocketOutput(c);
		s.output.ssl = ssl;
		return s;
	}

	public function peer() : { host : Host, port : Int } {
		var a : Dynamic = socket_peer(__s);
		var h = new Host("127.0.0.1");
		untyped h.ip = a[0];
		return { host : h, port : a[1] };
	}
	*/

	public function shutdown( read : Bool, write : Bool ) : Void {
		SSL_shutdown( ssl );
		socket_shutdown( __s, read, write );
	}

	public function host() : { host : Host, port : Int } {
		var a : Dynamic = socket_host( __s );
		var h = new Host( "127.0.0.1" );
		untyped h.ip = a[0];
		return { host : h, port : a[1] };
	}

	public function setTimeout( timeout : Float ) : Void {
		socket_set_timeout( __s, timeout );
	}

	public function waitForRead() : Void {
		select([this],null,null,null);
	}

	public function setBlocking( b : Bool ) : Void {
		socket_set_blocking(__s,b);
	}

	public function setFastSend( b : Bool ) : Void {
		socket_set_fast_send(__s,b);
	}

	private function initSSL() {
		SSL_library_init();
		SSL_load_error_strings();
	}

	private function buildSSLContext() : CTX {
		var ctx : CTX = SSL_CTX_new( SSLv23_client_method() );
		//if( validateCert ) {
		if( certFile != null && certFolder != null ) {
			var r : Int = SSL_CTX_load_verify_locations( ctx, certFile, certFolder );
			if( r == 0 )
				throw "Failed to load certificates";
			SSL_CTX_set_verify( ctx );
		}
		return ctx;
	}

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
	private static var TLSv1_client_method = load( 'TLSv1_client_method' );
	
	private static var SSL_CTX_new = load( 'SSL_CTX_new', 1 );
	private static var SSL_CTX_close = load( 'SSL_CTX_close', 1 );
	private static var SSL_CTX_load_verify_locations = load( 'SSL_CTX_load_verify_locations', 3 );
	private static var SSL_CTX_set_verify = load( 'SSL_CTX_set_verify', 1 );
	private static var SSL_CTX_use_certificate_file = load( 'SSL_CTX_use_certificate_file', 3 );
	
	private static var BIO_new_socket = load( "BIO_new_socket", 2 );
	private static var BIO_NOCLOSE = load( "BIO_NOCLOSE", 0 );
	
	private static var socket_read = load( '__SSL_read', 1 );
	private static var socket_write = load( '__SSL_write', 2 );
	//private static var socket_listen = lib( '__SSL_listen', 3 );
	private static var ssl_accept = load( '__SSL_accept', 1 );
	
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

#end //!php
