cd /etc/kubernetes/pki/
(umask 077; openssl genrsa -out chenliang.key 2048)
openssl req -new -key chenliang.key -out chenliang.csr -subj "/CN=chenliang/O=test_users"
openssl x509 -req -in chenliang.csr -CA ca.crt -CAkey ca.key  -CAcreateserial -out chenliang.crt -days 3650
openssl x509 -req -in chenliang.crt -text -noout
rm -rf chenliang.csr
