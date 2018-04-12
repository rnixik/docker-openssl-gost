#/bin/sh

mkdir -p /certs
# Generate new CA cert and key
openssl req -x509 -newkey gost2001 -pkeyopt paramset:A -nodes -days 10000 -keyout /certs/ca_key.pem -out /certs/ca_cert.crt -subj "/C=RU/L=Kemerovo/O=TEST GOST/CN=Test GOST CA"

# Generate new key for site
openssl genpkey -algorithm gost2001 -pkeyopt paramset:A -out /certs/gost.example.com.key

# Generate new request for site
openssl req -new -key /certs/gost.example.com.key -out /certs/gost.example.com.csr -subj "/C=RU/L=Kemerovo/O=My site with GOST/CN=gost.example.com"

# Sign request with CA
openssl x509 -req -in /certs/gost.example.com.csr -CA /certs/ca_cert.crt -CAkey /certs/ca_key.pem -CAcreateserial -out /certs/gost.example.com.crt -days 5000
