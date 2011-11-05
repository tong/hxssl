
OS = Linux
NDLL := ndll/$(OS)/tls.ndll
SSL_FLAGS := $(shell pkg-config --cflags --libs libcrypto)
NEKO_FLAGS := -I/usr/lib/neko/include -L/usr/lib/neko -lneko -lz -ldl
OBJS :=  src/_bio.o src/_evp.o src/_hmac.o src/_ssl.o

all : ndll

src/%.o : src/%.c
	$(CC) -I $(SSL_FLAGS) $(NEKO_FLAGS) -c $< -o $@
	
ndll : $(OBJS) Makefile
	$(CC) -shared -fPIC -o $(NDLL) $(NEKO_FLAGS) $(OBJS)

tests : $(NDLL)
	(cd test; haxe build.hxml)

haxelib:
	( cd ..; zip -r hxssl/hxssl.zip hxssl -x hxssl/.* hxssl/_* hxssl/.git\* )
	
haxelib-test: haxelib
	haxelib test hxssl.zip

install-ndll : $(NDLL)
	cp $(NDLL) /usr/lib/neko

clean :
	rm -f src/*.o
	rm -f $(NDLL)
	rm -f hxssl.zip

.PHONY: all tests clean
