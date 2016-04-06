
import haxe.Http;

class TestHttp extends haxe.unit.TestCase {

	static inline function req( urls : Array<String> ) {
		for( url in urls ) Http.requestUrl( url );
	}

	public function test_http() {
		req( ["http://www.w3.org/"] );
		assertTrue( true );
	}

	public function test_https_valid_cert() {
		var err = false;
		try {
			req([
				"https://www.google.com/",
				"https://www.nsa.gov/"
			]);
		} catch(e:Dynamic) {
			trace(e);
			err = true;
		}
		assertFalse( err );
	}


	public function test_https_invalid_cert() {

		//sys.ssl.Socket.defaultVerifyCertFile = true;
		var err = false;
		try {
			req([
				"https://tv.eurosport.com/"
			]);
		} catch(e:Dynamic) {
			trace(e);
			err = true;
		}
		assertTrue( err );

		/*
		//sys.ssl.Socket.defaultVerifyCertFile = false;
		var err = false;
		try {
			req([
				"https://tv.eurosport.com/"
			]);
		} catch(e:Dynamic) {
			trace(e);
			err = true;
		}
		assertFalse( err );
		*/
	}

	public function test_https_expired_cert() {
		var err = false;
		try {
			req([
				"https://testssl-expire.disig.sk/index.en.html"
			]);
		} catch(e:Dynamic) {
			trace(e);
			err = true;
		}
		assertTrue( err );
	}

	public function test_https_self_signed_cert() {
		var err = false;
		try {
			req([
				"https://www.pcwebshop.co.uk/"
			]);
		} catch(e:Dynamic) {
			trace(e);
			err = true;
		}
		assertFalse( err ); //TODO should pass ?
	}

}
