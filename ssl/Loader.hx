package ssl;

class Loader {
	
	public static function load( f : String, args : Int ) : Dynamic {
		return neko.Lib.load( "ssl", f, args );
	}
	
}
