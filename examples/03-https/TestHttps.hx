
import Sys.println;

class TestHttps {

	static inline var DEFAULT_URL = "https://www.nsa.gov/";

	static function main() {

		var url = Sys.args()[0];
		if( url == null ) url = DEFAULT_URL;

		println( 'Sending http request to $url' );

		var r = new haxe.Http( url );
		r.onData = println;
		r.onError = println;
		r.request();
	}
}
