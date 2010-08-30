
class TestSSLSocket {
	
	static function main() {
		
		var IP = 'talk.google.com';
		var JABBER_HOST = 'gmail.com';
		var PORT = 5223;
		
		var sock = new neko.ssl.Socket();
		neko.Lib.println( "Connecting to "+IP );
		sock.connect( neko.ssl.Socket.resolve( IP ), 443 );
		neko.Lib.println( "Connected." );
		neko.Lib.println( "Writing data to "+JABBER_HOST+" ..." );
		sock.write( '<?xml version="1.0" encoding="UTF-8"?><stream:stream xmlns:stream="http://etherx.jabber.org/streams" xmlns="jabber:client" to="'+JABBER_HOST+'" xml:lang="en" version="1.0">');
		neko.Lib.println( "Waiting for incoming XMPP stream ...." );
		var r = sock.read();
		neko.Lib.println( r );
		sock.close();
	}
	
}
