
import sys.crypto.SHA256;

class TestHttp extends haxe.unit.TestCase {
	
	function assertError (f:Void->Void) {
		var err:Bool;
		try {
			f();
			err = false;
		} catch (e:Dynamic) {
			err = true;
		}
		assertTrue( err );
	}

	public function test_http() {
		// Test regular http
		haxe.Http.requestUrl("http://www.w3.org/");
	}
	
	public function test_https_valid_cert() {
		// Test a valid https certificate
		haxe.Http.requestUrl("https://www.google.com/");
	}
	
	public function test_https_invalid_cert() {
		// Test a non-matching domain name
		assertError(function () {
			haxe.Http.requestUrl("https://tv.eurosport.com/");
		});
	}
	
	public function test_https_expired_cert() {
		// Test an expired certificate
		assertError(function () {
			haxe.Http.requestUrl("https://testssl-expire.disig.sk/index.en.html");
		});
	}
	
	public function test_https_self_signed_cert() {
		// Test a self signed certificate
		assertError(function () {
			haxe.Http.requestUrl("https://www.pcwebshop.co.uk/");
		});
	}
	
}
