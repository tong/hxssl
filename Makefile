
OS = Linux
INSTALL_PATH = /usr/lib/neko/
#SSL_FLAGS := $(shell pkg-config --cflags --libs libcrypto)
NDLL = ndll/$(OS)/tls.ndll
NEKOPATH = -I/usr/lib/neko/include
OBJS = src/_bio.o src/_evp.o src/_hmac.o src/_ssl.o \
	src/_base64.o

all: build

src/%.o: src/%.c
	$(CC) $(NEKOPATH) -c $< -o $@

$(NDLL): $(OBJS)
	$(CC) -shared -o $(NDLL) $(NEKOPATH) $(OBJS) -lssl -lcrypto
	
build: $(NDLL)

haxelib-zip: clean build
	(cd ..; zip -r hxssl/hxssl.zip hxssl -x hxssl/.* hxssl/_* hxssl/src*.o hxssl/.git )

haxelib-test: haxelib-zip
	haxelib test hxssl.zip

haxelib-submit: haxelib-zip
	haxelib submit hxssl.zip

install: build
	cp $(NDLL) $(INSTALL_PATH)
	
clean:
	rm -f src/*.o $(NDLL) hxssl.zip

.PHONY: all build install clean
