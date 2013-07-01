
import sys.ssl.Socket;
import sys.net.Host;

// haxe -x Client -lib ssl

class Client {

	static inline var HOST = 'localhost';
	static inline var PORT = 5000;

	static function main() {
		var s = new sys.ssl.Socket();
        s.connect(new Host("localhost"),5000);
        trace( "Connected" );
        s.write("hoi\n");
        while( true ) {
            var l = s.input.readLine();
            trace( l );
            if( l == "exit" ) {
                s.close();
                break;
            }
        }

	}
	
}
