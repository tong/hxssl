
class TestSSLSocket {
	
	static function main() {
		var JABBER_HOST = 'gmail.com';
		var sock = new neko.ssl.Socket();
		sock.connect( neko.ssl.Socket.resolve( "talk.google.com" ), 5223 );
		sock.write( '<?xml version="1.0" encoding="UTF-8"?><stream:stream xmlns:stream="http://etherx.jabber.org/streams" xmlns="jabber:client" to="'+JABBER_HOST+'" xml:lang="en" version="1.0">');
		trace( "Waiting ...." );
		var r = sock.read();
		trace( r );
	}
	
}
