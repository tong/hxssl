
SYSTEM = Linux

NDLL = ndll/$(SYSTEM)/tls.ndll
OBJS :=  src/_bio.o src/_evp.o src/_hmac.o src/_ssl.o
PATH_OPENSSL = /usr/local/ssl/include
SSL_PATH = /usr/lib/ssl

all : $(NDLL)

src/%.o : src/%.c
	$(CC) -I $(PATH_OPENSSL) -fPIC -c $< -o $@
	
$(NDLL) : $(OBJS) Makefile
	$(CC) -I$(PATH_OPENSSL) -I$(PATH_NEKO) -L$(SSL_PATH) -shared -fPIC -o $@ \
		-lstdc++ -ldl -lgc -lssl -lcrypto $(OBJS) \
		/usr/lib/libcrypto.a /usr/lib/libssl.a

test : $(NDLL)
	(cd test; haxe build.hxml)

install : $(NDLL)
	cp $(NDLL) /usr/lib/neko

clean :
	rm src/*.o
	rm $(NDLL)

.PHONY: all test install clean
	
