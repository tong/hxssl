
#
# hxssl
#

PROJECT=hxssl
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

all: ndll

$(NDLL): $(SRC)
	@(cd src;haxelib run hxcpp build.xml $(NDLL_FLAGS);)

ndll: $(NDLL)

test: $(HX_SRC) test/unit/*.hx*
	@(cd test/unit;haxe build.hxml $(HXCPP_FLAGS))
	@echo '---------------------------------------------------------'
	@(cd test/unit;neko test.n)
	@echo '---------------------------------------------------------'

ssl.zip: clean ndll
	zip -r $@ ndll/ sys/ haxelib.json README.md -x "*_*" "*.o"

haxelib: ssl.zip

install: haxelib
	haxelib local ssl.zip

uninstall:
	haxelib remove ssl

clean:
	rm -rf example/0*-*/cpp
	rm -f example/0*-*/test*
	rm -f $(NDLL)
	rm -rf src/obj
	rm -f ssl.zip

.PHONY: ndll haxelib install uninstall clean
