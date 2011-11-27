
#ifndef _BIO_H_
#define _BIO_H_

value _BIO_new_connect(value host_port);
value _ERR_load_BIO_strings();
value _BIO_do_connect(value bp);
value _BIO_read(value b, value data, value len);

#endif /* _BIO_H_ */
