
import sys.crypto.RIPEMD160;

class TestRIPEMD160 extends haxe.unit.TestCase {

	public function test() {
		assertEquals( "98c615784ccb5fe5936fbc0cbe9dfdb408d92f0f", RIPEMD160.encode("hello world") );
		assertEquals( "874fba7e643247866ff112e2d63e19e5ce429e24", RIPEMD160.encode("disktree") );
	}
}
