FROM debian:stretch-slim

RUN apt-get update && apt-get install build-essential wget git -y

# Build openssl
#ARG OPENSSL_VERSION=1.1.1b
#ARG OPENSSL_SHA256="5c557b023230413dfb0756f3137a13e6d726838ccd1430888ad15bfb2b43ea4b"
#RUN cd /usr/local/src \
#  && wget "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" -O "openssl-${OPENSSL_VERSION}.tar.gz" \
#  && echo "$OPENSSL_SHA256" "openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c - \
#  && tar -zxvf "openssl-${OPENSSL_VERSION}.tar.gz" \
#  && cd "openssl-${OPENSSL_VERSION}" \
#  && ./config shared -d --prefix=/usr/local/ssl --openssldir=/usr/local/ssl \
#  && make all && make install_sw \
#  && mv /usr/bin/openssl /root/ \
#  && ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl \
#  && rm -rf "/usr/local/src/openssl-${OPENSSL_VERSION}.tar.gz" "/usr/local/src/openssl-${OPENSSL_VERSION}"


ARG PREFIX="/usr/local/ssl"
RUN git clone --depth 1 -b master https://github.com/openssl/openssl.git \
  && cd openssl \
  && ./config shared -d --prefix=${PREFIX} --openssldir=${PREFIX} && make -j$(nproc) all && make install \
  && mv /usr/bin/openssl /root/ \
  && ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl

# Update path of shared libraries
RUN echo "/usr/local/ssl/lib" >> /etc/ld.so.conf.d/ssl.conf && ldconfig

ARG ENGINES=/usr/local/ssl/lib/engines-3

# Build GOST-engine for OpenSSL
ARG GOST_ENGINE_VERSION=af328b347cfbb3e4fa672b03700d70fdc8da892a
ARG GOST_ENGINE_SHA256="e013a87983f2c030316c4b897c1ea7a12aab4bd8e36231d9e0ead25bd401d5d1"
RUN apt-get update && apt-get install cmake unzip gcc -y \
  && cd /usr/local/src \
  && wget "https://github.com/gost-engine/engine/archive/${GOST_ENGINE_VERSION}.zip" -O gost-engine.zip \
  && echo "$GOST_ENGINE_SHA256" gost-engine.zip | sha256sum -c - \
  && unzip gost-engine.zip -d ./ \
  && cd "engine-${GOST_ENGINE_VERSION}" \
  && sed -i 's|printf("GOST engine already loaded\\n");|goto end;|' gost_eng.c \
  && mkdir build \
  && cd build \
  && cmake -DCMAKE_BUILD_TYPE=Release \
   -DOPENSSL_ROOT_DIR=/usr/local/ssl -DOPENSSL_LIBRARIES=/usr/local/ssl/lib -DOPENSSL_ENGINES_DIR=${ENGINES} .. \
  && cmake --build . --config Release \
  && cd bin \
  && cp gostsum gost12sum /usr/local/bin \
  && cd .. \
  && cp bin/gost.so "${ENGINES}" \
  && rm -rf "/usr/local/src/gost-engine.zip" "/usr/local/src/engine-${GOST_ENGINE_VERSION}"

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
  && echo "dynamic_path = ${ENGINES}/gost.so" >> /usr/local/ssl/openssl.cnf \
  && echo "default_algorithms = ALL" >> /usr/local/ssl/openssl.cnf \
  && echo "CRYPT_PARAMS = id-Gost28147-89-CryptoPro-A-ParamSet" >> /usr/local/ssl/openssl.cnf

# Rebuild curl
ARG CURL_VERSION=7.64.1
ARG CURL_SHA256="432d3f466644b9416bc5b649d344116a753aeaa520c8beaf024a90cba9d3d35d"
RUN apt-get remove curl -y \
  && rm -rf /usr/local/include/curl \
  && cd /usr/local/src \
  && wget "https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz" -O "curl-${CURL_VERSION}.tar.gz" \
  && echo "$CURL_SHA256" "curl-${CURL_VERSION}.tar.gz" | sha256sum -c - \
  && tar -zxvf "curl-${CURL_VERSION}.tar.gz" \
  && cd "curl-${CURL_VERSION}" \
  && CPPFLAGS="-I/usr/local/ssl/include" LDFLAGS="-L/usr/local/ssl/lib -Wl,-rpath,/usr/local/ssl/lib" LD_LIBRARY_PATH=/usr/local/ssl/lib \
   ./configure --prefix=/usr/local/curl --with-ssl=/usr/local/ssl --with-libssl-prefix=/usr/local/ssl \
  && make \
  && make install \
  && ln -s /usr/local/curl/bin/curl /usr/bin/curl \
  && rm -rf "/usr/local/src/curl-${CURL_VERSION}.tar.gz" "/usr/local/src/curl-${CURL_VERSION}" 

# Rebuild stunnel
ARG STUNNEL_VERSION=5.50
ARG STUNNEL_SHA256="951d92502908b852a297bd9308568f7c36598670b84286d3e05d4a3a550c0149"
RUN cd /usr/local/src \
  && wget "https://www.stunnel.org/downloads/stunnel-${STUNNEL_VERSION}.tar.gz" -O "stunnel-${STUNNEL_VERSION}.tar.gz" \
  && echo "$STUNNEL_SHA256" "stunnel-${STUNNEL_VERSION}.tar.gz" | sha256sum -c - \
  && tar -zxvf "stunnel-${STUNNEL_VERSION}.tar.gz" \
  && cd "stunnel-${STUNNEL_VERSION}" \
  && CPPFLAGS="-I/usr/local/ssl/include" LDFLAGS="-L/usr/local/ssl/lib -Wl,-rpath,/usr/local/ssl/lib" LD_LIBRARY_PATH=/usr/local/ssl/lib \
   ./configure --prefix=/usr/local/stunnel --with-ssl=/usr/local/ssl \
  && make \
  && make install \
  && ln -s /usr/local/stunnel/bin/stunnel /usr/bin/stunnel \
  && rm -rf "/usr/local/src/stunnel-${STUNNEL_VERSION}.tar.gz" "/usr/local/src/stunnel-${STUNNEL_VERSION}"
