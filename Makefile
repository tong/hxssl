
#
# hxssl
#

OS = Linux

uname_M := $(shell sh -c 'uname -m 2>/dev/null || echo not')
ifeq (${uname_M},x86_64)
	OS = Linux64
else ifeq (${uname_M},armv6l)
	OS = RPi
else ifeq (${uname_M},armv7l)
	OS = RPi
endif

NDLL:=ndll/$(OS)/ssl.ndll
SRC_PATHS:=src
CPP_SRCS:=src/hxssl_ssl.cpp src/hxssl_base64.cpp
OBJS:=${CPP_SRCS:.cpp=.o}

CX:=g++ -Isrc
SSL_FLAGS:=$(shell pkg-config --libs --cflags libssl)
NEKO_FLAGS:=-fpic -fPIC -DHX_LINUX -DHXCPP_VISIT_ALLOCS -I$(HXCPP)/include -ldl -fvisibility=hidden -O2
CPPFLAGS += $(SSL_FLAGS) $(NEKO_FLAGS)
LDFLAGS +=-fPIC -shared -L/usr/lib -lz -ldl -rdynamic -g3 -Xlinker --no-undefined $(SSL_FLAGS)

all: ndll

$(NDLL): $(OBJS)
	@mkdir -p ndll/$(OS)
	$(CX) $(CFLAGS) $(OBJS) -o $(NDLL) $(LDFLAGS)

ndll: $(NDLL)

ssl.zip: clean ndll
	zip -r $@ ndll src sys test/unit/*.hx* haxelib.json -x "_*" "*.o"
	
haxelib: ssl.zip

install: haxelib
	haxelib local ssl.zip

uninstall:
	haxelib remove ssl
		
clean:
	rm -f $(NDLL)
	rm -f $(OBJS)
	rm -f ssl.zip
