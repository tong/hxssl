
import Sys.println;

class TestHttps {

	static var URL = "https://thepiratebay.se";
	
	static function main() {
		var r = new haxe.Http( URL );
		r.certFolder = '/etc/ssl/certs';
		r.certFile = '/etc/ssl/certs/ca-certificates.crt';
		r.onData = println;
		r.onError = println;
		r.request();
	}
}
