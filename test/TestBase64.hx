
import sys.crypto.Base64;

/*
	$ echo -n "disktree" | openssl base64 
	$ echo -n "disktree" | base64 
	$ echo ZGlza3RyZWU= | base64 --decode
*/
class TestBase64 extends haxe.unit.TestCase {
	
	public function test_encode() {

		assertEquals( "dGVzdA==", Base64.encode( "test" ) );
		assertEquals( "SGVsbG8=", Base64.encode("Hello") );
		assertEquals( "SGVsbG8sIFdvcmxk", Base64.encode("Hello, World") );
		assertEquals( "ZGlza3RyZWU=", Base64.encode("disktree") );
		assertEquals( "Zm9v", Base64.encode("foo") );
		assertEquals( "Zm9vYg==", Base64.encode("foob") );
		assertEquals( "Zm9vYmE=", Base64.encode("fooba") );
		assertEquals( "Zm9vYmFy", Base64.encode("foobar") );
		assertEquals( "aGF4ZQ==", Base64.encode("haxe") );

		var t = "any carnal pleas";
		var te = "YW55IGNhcm5hbCBwbGVhcw==";
		assertEquals( te, Base64.encode( t ) );
		assertEquals( t, Base64.decode(te) );
		assertEquals( t, Base64.decode(Base64.encode(t)) );
		
		t = "any carnal pleasu";
		te = "YW55IGNhcm5hbCBwbGVhc3U=";
		assertEquals( te, Base64.encode( t ) );
		assertEquals( t, Base64.decode(te) );
		assertEquals( t, Base64.decode(Base64.encode(t)) );
		
		t = "any carnal pleasur";
		te = "YW55IGNhcm5hbCBwbGVhc3Vy";
		assertEquals( te, Base64.encode( t ) );
		assertEquals( t, Base64.decode(te) );
		assertEquals( t, Base64.decode(Base64.encode(t)) );
	}

	public function test_decode() {
		assertEquals( "test", Base64.decode( "dGVzdA==" ) );
		assertEquals( "Hello", Base64.decode( "SGVsbG8=" ) );
		assertEquals( "Hello, World", Base64.decode( "SGVsbG8sIFdvcmxk" ) );
		assertEquals( "disktree", Base64.decode("ZGlza3RyZWU=") );
		assertEquals( "foo", Base64.decode("Zm9v") );
		assertEquals( "foob", Base64.decode("Zm9vYg==") );
		assertEquals( "fooba", Base64.decode("Zm9vYmE=") );
		assertEquals( "foobar", Base64.decode("Zm9vYmFy") );

	}

	public function test_encode_decode() {
		assertEquals( "test", Base64.decode( Base64.encode( "test" ) ) );
		assertEquals( "foo", Base64.decode( Base64.encode( "foo" ) ) );
		assertEquals( "foobar", Base64.decode( Base64.encode( "foobar" ) ) );
		assertEquals( "fooba", Base64.decode( Base64.encode( "fooba" ) ) );
		assertEquals( "foob", Base64.decode( Base64.encode( "foob" ) ) );
		assertEquals( "foo", Base64.decode( Base64.encode( "foo" ) ) );
		assertEquals( "fo", Base64.decode( Base64.encode( "fo" ) ) );
		assertEquals( "f", Base64.decode( Base64.encode( "f" ) ) );
		var s = "Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure.";
		assertEquals( s, Base64.decode( StringTools.replace( Base64.encode(s), "\n", "" ) ) );
	}
	
}
