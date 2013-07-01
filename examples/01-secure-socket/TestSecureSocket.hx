
import haxe.io.Bytes;
import sys.ssl.Socket;

class TestSecureSocket {
	
	static function connectXMPPServer( ip : String, host : String, port : Int = 5223 ) {

		Sys.println( 'Connecting to : $ip ...' );
		
		var socket = new Socket();
		
		// Set cert paths
		switch( Sys.systemName() ) {
		case 'Linux':
			socket.setCertLocation( '/etc/ssl/certs/ca-certificates.crt', '/etc/ssl/certs' );
		default:
			trace("??????????????????????????????????????");
		}
		
		socket.connect( new sys.net.Host(ip), port );
		Sys.println( 'Connected' );
		
		Sys.println( 'Writing data to $host : $ip' );
		socket.write( '<?xml version="1.0" encoding="UTF-8"?><stream:stream xmlns:stream="http://etherx.jabber.org/streams" xmlns="jabber:client" to="$host" xml:lang="en" version="1.0">' );
		
		Sys.println( "Waiting for incoming XMPP stream ...." );
		
		var bufSize = 32;
		var buf = Bytes.alloc( 4096 );
		var pos = 0;
		var len : Int = -1;
		while( true ) {
			try {
				len = try socket.input.readBytes( buf, pos, bufSize );
			} catch( e : haxe.io.Eof ) {
				break;
			} catch( e : Dynamic ) {
				trace(e);
				return;
			}
			if( len < bufSize ) break else pos += len;

		}
		Sys.println( 'Recieved XMPP stream : '+buf.toString() );
		
		socket.write( '</stream>' );
		socket.close();
	}

	static function main() {
		connectXMPPServer( 'talk.google.com', 'talk.google.com' );
	}
	
}
