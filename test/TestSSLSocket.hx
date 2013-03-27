
import neko.tls.Socket;

class TestSSLSocket {
	
	static function main() {
		
		var IP = 'talk.google.com';
		var JABBER_HOST = 'gmail.com';
		var PORT = 5223;
		
		var sock = new Socket();
		Sys.println( "Connecting to "+IP );
		//sock.connect( Socket.resolve( IP ), 443 );
		sock.connect( new sys.net.Host(IP), 443 );
		Sys.println( "Connected." );
		
		Sys.println( "Writing data to "+JABBER_HOST+" ..." );
		sock.write( '<?xml version="1.0" encoding="UTF-8"?><stream:stream xmlns:stream="http://etherx.jabber.org/streams" xmlns="jabber:client" to="'+JABBER_HOST+'" xml:lang="en" version="1.0">');
		Sys.println( "Waiting for incoming XMPP stream ...." );
		
		var r = sock.read();
		Sys.println( r );
		sock.close();
	}
	
}
