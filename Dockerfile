FROM ubuntu:16.04

ARG OPENSSL_VERSION=1.1.0g
ARG GOST_ENGINE_VERSION=openssl_1_1_0
ARG CURL_VERSION=7.59.0

RUN apt-get update && apt-get install build-essential libssl-dev wget -y

# Build openssl
RUN cd /usr/local/src \
  && wget "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" -O "openssl-${OPENSSL_VERSION}.tar.gz" \
  && tar -zxvf "openssl-${OPENSSL_VERSION}.tar.gz" \
  && cd "openssl-${OPENSSL_VERSION}" \
  && ./config shared --prefix=/usr/local/ssl --openssldir=/usr/local/ssl -Wl,-rpath,/usr/local/ssl/lib \
  && make && make install \
  && mv /usr/bin/openssl /root/ \
  && ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl

# Update path of shared libraries
RUN echo "/usr/local/ssl/lib" >> /etc/ld.so.conf.d/ssl.conf && ldconfig

# Build GOST-engine for OpenSSL
RUN apt-get install git cmake unzip -y \
  && cd /usr/local/src \
  && wget "https://github.com/gost-engine/engine/archive/${GOST_ENGINE_VERSION}.zip" -O gost-engine.zip \
  && unzip gost-engine.zip -d ./ \
  && cd "engine-${GOST_ENGINE_VERSION}" \
  && mkdir build \
  && cd build \
  && cmake -DCMAKE_C_FLAGS='-I/usr/local/ssl/include -L/usr/local/ssl/lib' -DOPENSSL_ROOT_DIR=/usr/local/ssl  -DOPENSSL_INCLUDE_DIR=/usr/local/ssl/include -DOPENSSL_LIBRARIES=/usr/local/ssl/lib .. \
  && make \
  && cd ../bin \
  && cp gostsum gost12sum /usr/local/bin \
  && cd .. \
  && mkdir -p /usr/local/man/man1 \
  && cp gost12sum.1 gostsum.1 /usr/local/man/man1 \
  && cp bin/gost.so /usr/local/ssl/lib/engines-1.1

# Enable engine
RUN sed -i '6i openssl_conf=openssl_def' /usr/local/ssl/openssl.cnf \
  && echo "" >> /usr/local/ssl/openssl.cnf \
  && echo "# OpenSSL default section" >> /usr/local/ssl/openssl.cnf \
  && echo "[openssl_def]" >> /usr/local/ssl/openssl.cnf \
  && echo "engines = engine_section" >> /usr/local/ssl/openssl.cnf \
  && echo "" >> /usr/local/ssl/openssl.cnf \
  && echo "# Engine scetion" >> /usr/local/ssl/openssl.cnf \
  && echo "[engine_section]" >> /usr/local/ssl/openssl.cnf \
  && echo "gost = gost_section" >> /usr/local/ssl/openssl.cnf \
  && echo "" >> /usr/local/ssl/openssl.cnf \
  && echo "# Engine gost section" >> /usr/local/ssl/openssl.cnf \
  && echo "[gost_section]" >> /usr/local/ssl/openssl.cnf \
  && echo "engine_id = gost" >> /usr/local/ssl/openssl.cnf \
  && echo "dynamic_path = /usr/local/ssl/lib/engines-1.1/gost.so" >> /usr/local/ssl/openssl.cnf \
  && echo "default_algorithms = ALL" >> /usr/local/ssl/openssl.cnf \
  && echo "CRYPT_PARAMS = id-Gost28147-89-CryptoPro-A-ParamSet" >> /usr/local/ssl/openssl.cnf

# Rebuild curl
RUN apt-get remove curl -y \
  && rm -rf /usr/local/include/curl \
  && cd /usr/local/src \
  && wget "https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz" -O "curl-${CURL_VERSION}.tar.gz" \
  && tar -zxvf "curl-${CURL_VERSION}.tar.gz" \
  && cd "curl-${CURL_VERSION}" \
  && CPPFLAGS="-I/usr/local/ssl/include" LDFLAGS="-L/usr/local/ssl/lib" LD_LIBRARY_PATH=/usr/local/lib:/usr/local/ssl/lib ./configure --disable-shared --with-ssl=/usr/local/ssl --with-libssl-prefix=/usr/local/ssl \
  && make \
  && make install

