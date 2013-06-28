
import sys.crypto.SHA1;

class TestSHA1 extends haxe.unit.TestCase {

	public function test() {

		assertEquals( "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", SHA1.encode('test') );
		assertEquals( "082fd04d158acacd994947f7716881b36cafa047", SHA1.encode('disktree') );
		
		/*
		var t = "disktree";
		assertEquals( "514d26cfd4c8b8105a6e7cf64d5cce10", MD5.encode(t) );
		
		t = "The quick brown fox jumps over the lazy dog";
		assertEquals( "9e107d9d372bb6826bd81d3542a419d6", MD5.encode(t) );
		
		t = "The quick brown fox jumps over the lazy cog";
		assertEquals( "1055d3e698d289f2af8663725127bd4b", MD5.encode(t) );
		
		t = "disktree";
		assertEquals( "514d26cfd4c8b8105a6e7cf64d5cce10", MD5.encode(t) );
		t = "514d26cfd4c8b8105a6e7cf64d5cce10";
		assertEquals( "a5a67ee535bcf341f5600d82bf09dcb6", MD5.encode(t) );
		
		*/
	}
	
}
