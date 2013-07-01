
import sys.ssl.Socket;
import sys.net.Host;

// TODO socket.listen not implemented yet

class TestSecureSocketServer {

	public static inline var HOST = 'localhost';
	public static inline var PORT = 5000;

	static function main() {
		var s = new Socket();
        s.bind( new Host( HOST ), PORT );
        s.listen( 10 );
        trace( "Starting server..." );
        while( true ) {
            var c : sys.ssl.Socket = s.accept();
            trace( "Client connected..." );
            var l = s.input.readLine();
            trace(l);
            /*
            c.write("your IP is "+c.peer().host.toString()+"\n");
            c.write("exit");
            c.close();
            trace( "Client disconnected" );
            */
        }
	}
	
}
