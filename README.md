
# HXSSL [![Build Status](https://travis-ci.org/tong/hxssl.svg?branch=master)](https://travis-ci.org/tong/hxssl) [![Haxelib Version](https://img.shields.io/github/tag/tong/hxssl.svg?style=flat&label=haxelib)](http://lib.haxe.org/p/hxssl)

Haxe Cpp/Neko [OpenSSL](https://www.openssl.org/) bindings.


### Build

```sh

## Download openssl (you might want to use another version)
wget -P openssl/project/tars/ ftp://ftp.openssl.org/source/openssl-1.0.2g.tar.gz

## Build the build.n script:
cd openssl/tools; haxe compile.hxml

## Use the build.n script to build the library:
cd openssl/project; neko build.n

## Build the ndll
cd src; haxelib run hxcpp build.xml
```
