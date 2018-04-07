# Docker image with OpenSSL 1.1.0, GOST engine and cURL

This image was built to have ability to connect to servers with GOST SSL certificates.
In addition, it helps to encrypt, decrypt, hash messages with GOST algorithms.

Since version 1.1.0 OpenSSL does not contain GOST-engine anymore, but it can be compiled and used separately.
This image does this work.

Output of `openssl ciphers`:

ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:DHE-RSA-AES256-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA:RSA-PSK-AES256-GCM-SHA384:DHE-PSK-AES256-GCM-SHA384:RSA-PSK-CHACHA20-POLY1305:DHE-PSK-CHACHA20-POLY1305:ECDHE-PSK-CHACHA20-POLY1305:AES256-GCM-SHA384:PSK-AES256-GCM-SHA384:PSK-CHACHA20-POLY1305:RSA-PSK-AES128-GCM-SHA256:DHE-PSK-AES128-GCM-SHA256:AES128-GCM-SHA256:PSK-AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:ECDHE-PSK-AES256-CBC-SHA384:ECDHE-PSK-AES256-CBC-SHA:SRP-RSA-AES-256-CBC-SHA:SRP-AES-256-CBC-SHA:RSA-PSK-AES256-CBC-SHA384:DHE-PSK-AES256-CBC-SHA384:RSA-PSK-AES256-CBC-SHA:DHE-PSK-AES256-CBC-SHA:GOST2012-GOST8912-GOST8912:GOST2001-GOST89-GOST89:AES256-SHA:PSK-AES256-CBC-SHA384:PSK-AES256-CBC-SHA:ECDHE-PSK-AES128-CBC-SHA256:ECDHE-PSK-AES128-CBC-SHA:SRP-RSA-AES-128-CBC-SHA:SRP-AES-128-CBC-SHA:RSA-PSK-AES128-CBC-SHA256:DHE-PSK-AES128-CBC-SHA256:RSA-PSK-AES128-CBC-SHA:DHE-PSK-AES128-CBC-SHA:AES128-SHA:PSK-AES128-CBC-SHA256:PSK-AES128-CBC-SHA

The main part is:
```
GOST2012-GOST8912-GOST8912
GOST2001-GOST89-GOST89
```

Take a look to GOST-engine documentation: https://github.com/gost-engine/engine/blob/master/README.gost

There are some issues with OpenSSL 1.1.0h and GOST-engine (GOST ciphers are not in list), so versions are fixed in default docker's build args.


## Usage

The image has been built and pushed into https://hub.docker.com/r/rnix/openssl-gost/.
In examples below I use image *rnix/openssl-gost* from Docker Hub, but you can build this image for you own and use your tag.

As usual, you can run commands directly from host or you can use 'interactive mode' with `-i`.
Pull the image and run a container with mounted current dir in interactive mode:

```
docker run --rm -i -t -v `pwd`:`pwd` -w `pwd` rnix/openssl-gost bash
```
Run command with mounted current dir without interactive mode:

```
docker run --rm -v `pwd`:`pwd` -w `pwd` rnix/openssl-gost openssl version
```

If you use Windows, `pwd` is incorrect. Use absolute path instead, for example:
```
docker run --rm -i -t -v /c/workspace/:/c/workspace/ -w /c/workspace/ rnix/openssl-gost bash
```
    
In the container you run commands.


## Examples

To show certificate of host with GOST
```
openssl s_client -connect gost.example.com:443 -showcerts
```

To send a file to host with POST and save the response into new file
```
curl -X POST --data-binary @file.txt https://gost.example.com --output response.txt
```

To generate new key and certificate with Signature Algorithm: GOST R 34.11-94 with GOST R 34.10-2001
```
openssl req -x509 -newkey gost2001 -pkeyopt paramset:A -nodes -keyout key.pem -out cert.pem
```

To sign file with electronic signature by GOST using public certificate (-signer cert.pem),
private key (-inkey key.pem), with opaque signing (-nodetach),
DER as output format without including certificate and attributes (-nocerts -noattr):
```
openssl cms -sign -signer cert.pem -inkey key.pem -binary -in file.txt -nodetach -outform DER -nocerts -noattr -out signed.sgn
```

To extract data (verify) from signed file (DER-format) using public certificate (-certfile cert.pem) 
issued by CA (-CAfile cert.pem) (the same because cert.pem is self-signed):
```
openssl cms -verify -in signed.sgn -certfile cert.pem -CAfile cert.pem -inform der -out data.txt
```

More examples with GOST can be found here: https://github.com/gost-engine/engine/blob/master/README.gost


## Certification authority (CA)

In Russia, it is common to issue GOST-certificates signed by CA which are not worldwide trusted.
In this case you get error. For example, `curl: (60) SSL certificate problem: unable to get local issuer certificate`.
To solve this problem you have two options: 1) do not verify CA (not recommended), 2) find and use CA.

1. To ignore security error use `-k` with curl and `-noverify` with openssl. 
For example `curl https://gost.examples.com -k` or `openssl cms -verify -noverify`.

2. Find and download CA-certificate file. 
For example, [CryptoPRO CA](http://cpca.cryptopro.ru/cacer.p7b). It is PKCS7, but you need PEM.
Run command to extract all certificates from p7b and write them as a chain of certificates in one file:
```
openssl pkcs7 -inform DER -outform PEM -in cacer.p7b -print_certs > crypto_pro_ca_bundle.crt
```

When you have CA-file you can: 

* Install it in default CA certificate store
* Specify it in every openssl or curl command

To install it in default CA certificate store use commands:
```
cp crypto_pro_ca_bundle.crt /usr/local/share/ca-certificates/
update-ca-certificates
```

To specify it in curl:
```
curl https://gost.example.com/ --cacert crypto_pro_ca_bundle.crt
```

To specify it in openssl with verifying signature:
```
openssl cms -verify -in signed.txt -signer cert.pem -inform DER -CAfile crypto_pro_ca_bundle.crt -out unsigned.txt
```


## License

    The MIT License

    Copyright (C) 2018 Roman Nix

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

