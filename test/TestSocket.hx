
import sys.crypto.SHA256;

class TestSocket extends haxe.unit.TestCase {

	public function test_connect_ssl() {
		var socket = new sys.ssl.Socket();
		socket.connect( new sys.net.Host( "talk.google.com" ), 5223 );
		socket.close();
		assertTrue( true );
	}
	
}
