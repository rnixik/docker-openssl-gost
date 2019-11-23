FROM rnix/openssl-gost AS openssl-gost

# Replace with any other image based on Debian x86_64
FROM debian:stretch-slim

COPY --from=openssl-gost /usr/local/ssl /usr/local/ssl
COPY --from=openssl-gost /usr/local/ssl/bin/openssl /usr/bin/openssl
COPY --from=openssl-gost /usr/local/curl /usr/local/curl
COPY --from=openssl-gost /usr/local/curl/bin/curl /usr/bin/curl
COPY --from=openssl-gost /usr/local/bin/gostsum /usr/local/bin/gostsum
COPY --from=openssl-gost /usr/local/bin/gost12sum /usr/local/bin/gost12sum

# It is not necessary, but depends on the configuring script
COPY --from=openssl-gost /usr/local/ssl/lib/pkgconfig/* /usr/lib/x86_64-linux-gnu/pkgconfig/
COPY --from=openssl-gost /usr/local/curl/lib/pkgconfig/* /usr/lib/x86_64-linux-gnu/pkgconfig/

RUN echo "/usr/local/ssl/lib" >> /etc/ld.so.conf.d/ssl.conf && ldconfig

# Add compiling instuctions with custom OpenSSL and cUrl
