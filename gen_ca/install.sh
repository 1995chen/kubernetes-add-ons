openssl genrsa -out nginx.key 2048
openssl req -new -sha256 -out ca.csr -key nginx.key -config openssl.conf
openssl x509 -req -days 3650 -in ca.csr -signkey nginx.key -out ca.crt
