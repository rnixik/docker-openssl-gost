# Dockerfile for nginx with GOST TLS support

Contains nginx, openssl and gost-engine.

## Nginx with default configuration:

* Dockerfile

It has been built and pushed to Docker Hub.

To pull it:
```
docker pull rnix/nginx-gost
```


## Nginx with demo GOST-certificates and custom nginx.conf for https://gost.example.com

* Dockerfile_gost_example_com - based on main
* gen_demo_gost_certs.sh - generates demo certificats, run in Dockerfile_gost_example_com
* gost.conf - custom nginx.conf, used in Dockerfile_gost_example_com

To run demo gost.example.com:

```
docker network create gost-network
docker build -f Dockerfile_gost_example_com -t gost-example-com .
docker run -d --rm --network=gost-network --name gost.example.com gost-example-com
```

To test it you need something with GOST-support, for example, curl:
```
docker run --rm -t --network=gost-network rnix/openssl-gost curl https://gost.example.com -k
```

Example should contain response from Google, usually, it is `302 Moved`.

