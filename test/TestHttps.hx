
import neko.Lib;
import neko.tls.Socket;

private class ClosableBytesOutput extends haxe.io.BytesOutput {
	public dynamic function onClose() {}
	public function new() super();
	override public function close() {
		super.close();
		onClose();
	}
}

class TestHttps {

	static function main() {

		var args = Sys.args();
		if (args.length < 1) {
			Lib.println( "Usage: TestHttps.n <url>" );
			return;
		}
		var parts = args[0].split("/");
		var url = parts.shift() + if( parts.length == 0 ) "" else "/" + parts.join("/");

		Sys.println( "Requesting from URL: "+url );

		var https : haxe.Http = new haxe.Http( url );
		var output  = new ClosableBytesOutput();
		output.onClose = function() {
			https.onData( Lib.stringReference(output.getBytes()) );
		};
		https.onData = function( data : String ) {
			trace( "https.Data:\n"+data+"\n" );			
		}
		https.onError = function( msg : String ) {
			trace( "https.Error:"+msg+"\n" );
		}
		
		https.onStatus=function(status : Int){
			trace ("https.Status:"+status+"\n");
		}
		trace( "Before async request" );
		https.customRequest( false, output );
		trace( "After async request" );		
	}
	
}
