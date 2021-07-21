#!/bin/bash

docker build -t openssl-gost-local .

docker run -it --rm openssl-gost-local bash -c "openssl ciphers | grep 'GOST2012-GOST8912-GOST8912' && echo OK || echo FAIL"
docker run -it --rm openssl-gost-local curl https://alpha.demo.nbki.ru/main -k && echo "OK" || echo "FAIL"
docker run -it --rm openssl-gost-local curl https://zakupki.gov.ru -k && echo "OK" || echo "FAIL"
docker run -it --rm openssl-gost-local curl https://portal.rosreestr.ru:4455 -k && echo "OK" || echo "FAIL"
