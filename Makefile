##
## hxssl
##

PROJECT=hxssl
OS=Linux
DEBUG=false
NDLL_FLAGS=
HXCPP_FLAGS=
OS=$(shell sh -c 'uname -s 2>/dev/null || echo not')
MACHINE=$(shell sh -c 'uname -m 2>/dev/null || echo not')

ifeq ($(OS),Linux)
	ifeq ($(MACHINE),$(filter $(MACHINE),armv6l armv7l))
		OS=RPi
		NDLL_FLAGS+=-DRPi
		HXCPP_FLAGS+=-D RPi
	else ifeq ($(MACHINE),x86_64)
		OS=Linux64
		NDLL_FLAGS+=-DHXCPP_M64
		HXCPP_FLAGS+=-D HXCPP_M64
	else
		OS=Linux
	endif
else ifeq ($(OS),Darwin)
	ifeq ($(MACHINE),x86_64)
		OS=Mac64
		NDLL_FLAGS+=-DHXCPP_M64
		HXCPP_FLAGS+=-D HXCPP_M64
	else ifeq ($(MACHINE),i686)
		OS=Mac
	endif
else ifeq ($(OS),Windows_NT)
	OS=Windows
	NDLL_FLAGS+=-DWindows
	HXCPP_FLAGS+=-D Windows
endif

ifeq ($(DEBUG),true)
	HXCPP_FLAGS+=-debug
else
	HXCPP_FLAGS+=--no-traces -dce full
endif

NDLL=ndll/$(OS)/$(PROJECT).ndll
SRC_CPP=src/*.cpp
SRC_HX=sys/crypto/*.hx sys/ssl/*.hx

$(NDLL): $(SRC_CPP)
	@echo "\nBuilding ndll for $(OS) ($(MACHINE))\n"
	@(cd openssl/tools;haxe compile.hxml)
	@(cd openssl/project;neko build.n)
	@(cd src;haxelib run hxcpp build.xml $(NDLL_FLAGS))

ndll: $(NDLL)

examples: $(SRC_HX)
	@(cd examples/01-*/;haxe build.hxml $(HXCPP_FLAGS))
	#@(cd examples/02-*/;haxe build.hxml $(HXCPP_FLAGS))
	@(cd examples/03-*/;haxe build.hxml $(HXCPP_FLAGS))

test-cpp: $(SRC_HX) test/*.hx*
	@(cd test;haxe build-cpp.hxml $(HXCPP_FLAGS))
	@(cd test;./Run)

test/run.n: $(SRC_HX) test/*.hx*
	@(cd test;haxe build-neko.hxml;neko run.n)

test-neko: test/test.n
	@(cd test;haxe build-neko.hxml;neko test.n)

test: test-cpp test-neko

hxssl.zip: clean ndll
	zip -r $@ ndll/ src/build.xml src/*.cpp examples/ haxe/ sys/ test/ Makefile haxelib.json README.md -x "*.o"

haxelib: hxssl.zip

install: haxelib
	haxelib local hxssl.zip

uninstall:
	haxelib remove hxssl

clean:
	rm -f $(NDLL)
	rm -rf src/obj
	rm -f src/all_objs
	rm -f src/*.o
	rm -rf test/cpp
	rm -f test/run.n
	rm -f test/Run
	rm -f $(PROJECT).zip
	cd examples && rm -rf 0*-*/cpp 0*-*/cs 0*-*/java && rm -f 0*-*/test-*

.PHONY: ndll examples test test-cpp test-neko haxelib install uninstall clean
