HXSSL
=====
Haxe Cpp/Neko OpenSSL bindings  

[![Build Status](https://travis-ci.org/tong/hxssl.svg?branch=master)](https://travis-ci.org/tong/hxssl)

### First build openssl
* Build the 'build.n' script:  cd openssl/tools; haxe compile.hxml
* Use the build.n script to build the library: cd openssl/project; neko build.n

### Next build the ndll
* cd src; haxelib run hxcpp build.xml
