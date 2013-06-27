
#
# hxssl
#

OS=Linux
NDLL_FLAGS=
HX_FLAGS=

#LBITS := $(shell getconf LONG_BIT)
uname_M := $(shell sh -c 'uname -m 2>/dev/null || echo not')
ifeq (${uname_M},i686)
	OS=Linux
else ifeq (${uname_M},x86_64)
	OS=Linux64
	HX_FLAGS+=-D HXCPP_M64
else ifeq (${uname_M},armv6l)
	OS=RPi
	NDLL_FLAGS+=-DRASPBERRYPI
	HX_FLAGS+=-D RPi
else ifeq (${uname_M},armv7l)
	OS=RPi
	NDLL_FLAGS+=-DRASPBERRYPI
	HX_FLAGS+=-D RPi
endif

HX_SRC = sys/crypto/*.hx sys/ssl/*.hx
SRC_PATHS:=src
SRCS:=src/hxssl_ssl.cpp src/hxssl_base64.cpp src/hxssl_md5.cpp
OBJS:=${SRCS:.cpp=.o}
NDLL=ndll/$(OS)/ssl.ndll
HXCPP=$(shell haxelib path hxcpp | head -1)

CX:=g++ -Isrc
SSL_FLAGS:=$(shell pkg-config --libs --cflags libssl)

NEKO_FLAGS:=-fpic -fPIC -DHX_LINUX -DHXCPP_VISIT_ALLOCS -I$(HXCPP)/include -ldl -fvisibility=hidden -O2
CPPFLAGS+=$(SSL_FLAGS) $(NEKO_FLAGS) $(NDLL_FLAGS)
CFLAGS+=$(SSL_FLAGS) $(NEKO_FLAGS) $(NDLL_FLAGS)
LDFLAGS+=-fPIC -shared -L/usr/lib -lz -ldl -rdynamic -g3 -Xlinker --no-undefined $(SSL_FLAGS)

all: ndll

$(NDLL): $(OBJS)
	@mkdir -p ndll/$(OS)
	$(CX) $(CFLAGS) $(OBJS) -o $(NDLL) $(LDFLAGS)

ndll: $(NDLL)

hxssl.zip: clean ndll
	zip -r $@ ndll src sys test/unit/*.hx* haxelib.json -x "_*" "*.o"

test: $(HX_SRC) test/unit/*.hx
	@(cd test/unit; haxe build.hxml $(HX_FLAGS); neko test.n)

haxelib: hxssl.zip

install: haxelib
	haxelib local hxssl.zip

uninstall:
	haxelib remove hxssl
		
clean:
	rm -rf example/01-secure-socket/cpp
	rm -f example/01-secure-socket/test*
	rm -rf example/02-https/cpp
	rm -f example/02-https/test*
	rm -rf example/03-secure-server/cpp
	rm -f example/03-secure-server/test*
	rm -f $(NDLL)
	rm -f $(OBJS)
	rm -rf test/unit/cpp
	rm -f test/unit/test*
	rm -f hxssl.zip
