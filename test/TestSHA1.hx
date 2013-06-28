
import sys.crypto.SHA1;

class TestSHA1 extends haxe.unit.TestCase {

	public function test() {
		assertEquals( "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", SHA1.encode('test') );
		assertEquals( "082fd04d158acacd994947f7716881b36cafa047", SHA1.encode('disktree') );
		assertEquals( "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12", SHA1.encode('The quick brown fox jumps over the lazy dog') );
	}
	
}
