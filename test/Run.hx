
class Run {
	
	static function main() {

		var r = new haxe.unit.TestRunner();
		
		r.add( new TestBase64() );
		r.add( new TestMD5() );
		r.add( new TestSHA1() );
		r.add( new TestSHA256() );
		r.add( new TestRIPEMD160() );
		#if !cpp
		//FIXME https is broken for cpp in Haxe until this commit: https://github.com/HaxeFoundation/haxe/commit/b8a98987586a83900db54463eee66299c715cfb9
		r.add( new TestHttp() );
		#end
		r.add( new TestSocket() );
		
		if (r.run()) {
			Sys.exit(0);
		} else {
			Sys.exit(1);
		}
	}
	
}
