
class TestHttps {
	
	static function main() {
		var r = new haxe.Http('https://thepiratebay.sx/');
		r.certFolder = '/etc/ssl/certs';
		r.certFile = '/etc/ssl/certs/ca-certificates.crt';
		r.onData = function(data){
			Sys.println( data );
		};
		r.onError = function(error){
			Sys.println( error );
		};
		r.request();
	}
}
