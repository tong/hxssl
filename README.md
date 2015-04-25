HXSSL
=====
Haxe Cpp/Neko OpenSSL bindings  

[![Build Status](https://travis-ci.org/tong/hxssl.svg?branch=master)](https://travis-ci.org/tong/hxssl)

### Windows build
Modify your .hxcpp_config.xml to integrate openssl library ( you can download standalone ones or cygwin ones ).
Add a define for snprintf which is no longer supported
Comment out non win compatible SOCKET things ( should be normalized in a separate header )
Hint the compiler for the lib inclusion : #pragma comment (lib, "Ws2_32.lib")
