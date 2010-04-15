#ifdef WIN32
__declspec(dllexport)
#endif
value _HMAC(const value evp_md, const value key, value key_len, const value d, value n, value md, value md_len);
#ifdef WIN32
__declspec(dllexport)
#endif
value _HMAC_EVP_sha1(value key, value d);

