
import sys.crypto.SHA256;

class TestSHA256 extends haxe.unit.TestCase {

	public function test() {
		assertEquals( "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", SHA256.encode('test') );
		assertEquals( "208c411ea00b63fbaa462f7186fc487762f27ef2f86ed35084b8eac4344cffa6", SHA256.encode('disktree') );
		assertEquals( "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592", SHA256.encode('The quick brown fox jumps over the lazy dog') );
	}
	
}
