
#
# hxssl
#

OS=Linux
NDLL_FLAGS=
SRC = src/*.cpp
HX_SRC = sys/crypto/*.hx sys/ssl/*.hx
HXCPP_FLAGS =

uname_M := $(shell sh -c 'uname -m 2>/dev/null || echo not')
ifeq (${uname_M},x86_64)
	OS = Linux64
	NDLL_FLAGS += -DHXCPP_M64
	HXCPP_FLAGS += -D HXCPP_M64
else ifeq (${uname_M},armv6l)
	OS = RPi
	HXCPP_FLAGS += -D RPi
else ifeq (${uname_M},armv7l)
	OS = RPi
	HXCPP_FLAGS += -D RPi
endif

NDLL = ndll/$(OS)/ssl.ndll

all: ndll #test examples

$(NDLL): $(SRC)
	@(cd src;haxelib run hxcpp build.xml $(NDLL_FLAGS);)

ndll: $(NDLL)

examples: $(SRC)
	(cd examples/01-*/;haxe build.hxml $(HXCPP_FLAGS))
	(cd examples/02-*/;haxe build.hxml $(HXCPP_FLAGS))
	(cd examples/03-*/;haxe build.hxml $(HXCPP_FLAGS))

test-cpp: $(HX_SRC) test/*.hx*
	@(cd test;haxe build-cpp.hxml $(HXCPP_FLAGS))
	@(cd test;./test)

test-neko: $(HX_SRC) test/*.hx*
	@(cd test;haxe build-neko.hxml)
	@(cd test;neko test.n)

test: test-cpp test-neko

ssl.zip: clean ndll
	zip -r $@ ndll/ sys/ haxelib.json README.md -x "*_*" "*.o"

haxelib: ssl.zip

install: haxelib
	haxelib local ssl.zip

uninstall:
	haxelib remove ssl

clean:
	rm -rf examples/0*-*/cpp
	rm -f examples/0*-*/test*
	rm -f $(NDLL)
	rm -rf src/obj
	rm -rf test/cpp
	rm -f test/test*
	rm -f ssl.zip

.PHONY: ndll examples tests haxelib install uninstall clean
