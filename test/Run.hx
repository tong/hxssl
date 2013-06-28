
class Run {
	
	static function main() {
		var r = new haxe.unit.TestRunner();
		r.add( new TestBase64() );
		r.add( new TestMD5() );
		r.add( new TestSHA1() );
		r.run();
	}
	
}
