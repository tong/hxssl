
import Sys.println;

class TestHttps {

	static var URL = "https://thepiratebay.se";
	
	static function main() {
		var r = new haxe.Http( URL );
		r.onData = println;
		r.onError = println;
		r.request();
	}
}
