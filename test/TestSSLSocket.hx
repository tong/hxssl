
class TestSSLSocket {
	
	static function main() {
		var sock = new ssl.SSLSocket();
		sock.connect( ssl.SSLSocket.resolve( "talk.google.com" ), 5223 );
		//sock.connect( ssl.SSLSocket.resolve( "192.168.0.110" ), 5223 );
		var JABBER_HOST = 'gmail.com';
		//var JABBER_HOST = 'disktree';
		sock.write( '<?xml version="1.0" encoding="UTF-8"?><stream:stream xmlns:stream="http://etherx.jabber.org/streams" xmlns="jabber:client" to="'+JABBER_HOST+'" xml:lang="en" version="1.0">');
		trace( "Waiting ...." );
		var r = sock.read();
		trace( r );
	}
	
}
