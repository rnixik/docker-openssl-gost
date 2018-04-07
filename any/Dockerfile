FROM rnix/openssl-gost AS openssl-gost

# Replace with any other based on Debian x86_64
FROM debian:jessie

COPY --from=openssl-gost /usr/local/ssl /usr/local/ssl
COPY --from=openssl-gost /usr/local/ssl/bin/openssl /usr/bin/openssl
COPY --from=openssl-gost /usr/local/curl /usr/local/curl
COPY --from=openssl-gost /usr/local/curl/bin/curl /usr/bin/curl
COPY --from=openssl-gost /usr/local/bin/gostsum  /usr/local/bin/gostsum
COPY --from=openssl-gost /usr/local/bin/gost12sum  /usr/local/bin/gost12sum

# Add compiling instuctions with custom OpenSSL and cUrl
