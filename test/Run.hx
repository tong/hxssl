
class Run {

	static function main() {

		var r = new haxe.unit.TestRunner();

		r.add( new TestBase64() );
		r.add( new TestMD5() );
		r.add( new TestSHA1() );
		r.add( new TestSHA256() );
		r.add( new TestRIPEMD160() );
		r.add( new TestHttp() );
		r.add( new TestSocket() );

		if (r.run()) {
			Sys.exit(0);
		} else {
			Sys.exit(1);
		}
	}

}
