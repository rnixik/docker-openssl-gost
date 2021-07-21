FROM debian:stretch-slim

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install build-essential wget git cmake unzip gcc -y

ARG PREFIX="/usr/local/ssl"

# Build openssl
ARG OPENSSL_VERSION="OpenSSL_1_1_1d"
ARG OPENSSL_SHA256="a366e3b6d8269b5e563dabcdfe7366d15cb369517f05bfa66f6864c2a60e39e8"
RUN cd /usr/local/src \
  && wget "https://github.com/openssl/openssl/archive/${OPENSSL_VERSION}.zip" -O "${OPENSSL_VERSION}.zip" \
  && echo "$OPENSSL_SHA256" "${OPENSSL_VERSION}.zip" | sha256sum -c - \
  && unzip "${OPENSSL_VERSION}.zip" -d ./ \
  && cd "openssl-${OPENSSL_VERSION}" \
  && ./config shared -d --prefix=${PREFIX} --openssldir=${PREFIX} && make -j$(nproc) all && make install \
  && mv /usr/bin/openssl /root/ \
  && ln -s ${PREFIX}/bin/openssl /usr/bin/openssl

# Update path of shared libraries
RUN echo "${PREFIX}/lib" >> /etc/ld.so.conf.d/ssl.conf && ldconfig

ARG ENGINES=${PREFIX}/lib/engines-3

# Build GOST-engine for OpenSSL
ARG GOST_ENGINE_VERSION=58a46b289d6b8df06072fc9c0304f4b2d3f4b051
ARG GOST_ENGINE_SHA256="6b47e24ee1ce619557c039fc0c1201500963f8f8dea83cad6d05d05b3dcc2255"
RUN cd /usr/local/src \
  && wget "https://github.com/gost-engine/engine/archive/${GOST_ENGINE_VERSION}.zip" -O gost-engine.zip \
  && echo "$GOST_ENGINE_SHA256" gost-engine.zip | sha256sum -c - \
  && unzip gost-engine.zip -d ./ \
  && cd "engine-${GOST_ENGINE_VERSION}" \
  && sed -i 's|printf("GOST engine already loaded\\n");|goto end;|' gost_eng.c \
  && mkdir build \
  && cd build \
  && cmake -DCMAKE_BUILD_TYPE=Release \
   -DOPENSSL_ROOT_DIR=${PREFIX} -DOPENSSL_LIBRARIES=${PREFIX}/lib -DOPENSSL_ENGINES_DIR=${ENGINES} .. \
  && cmake --build . --config Release \
  && cmake --build . --target install --config Release \
  && cd bin \
  && cp gostsum gost12sum /usr/local/bin \
  && cd .. \
  && rm -rf "/usr/local/src/gost-engine.zip" "/usr/local/src/engine-${GOST_ENGINE_VERSION}"

# Enable engine
RUN sed -i '6i openssl_conf=openssl_def' ${PREFIX}/openssl.cnf \
  && echo "" >>${PREFIX}/openssl.cnf \
  && echo "# OpenSSL default section" >>${PREFIX}/openssl.cnf \
  && echo "[openssl_def]" >>${PREFIX}/openssl.cnf \
  && echo "engines = engine_section" >>${PREFIX}/openssl.cnf \
  && echo "" >>${PREFIX}/openssl.cnf \
  && echo "# Engine scetion" >>${PREFIX}/openssl.cnf \
  && echo "[engine_section]" >>${PREFIX}/openssl.cnf \
  && echo "gost = gost_section" >>${PREFIX}/openssl.cnf \
  && echo "" >> ${PREFIX}/openssl.cnf \
  && echo "# Engine gost section" >>${PREFIX}/openssl.cnf \
  && echo "[gost_section]" >>${PREFIX}/openssl.cnf \
  && echo "engine_id = gost" >>${PREFIX}/openssl.cnf \
  && echo "dynamic_path = ${ENGINES}/gost.so" >>${PREFIX}/openssl.cnf \
  && echo "default_algorithms = ALL" >>${PREFIX}/openssl.cnf \
  && echo "CRYPT_PARAMS = id-Gost28147-89-CryptoPro-A-ParamSet" >>${PREFIX}/openssl.cnf

# Rebuild curl
ARG CURL_VERSION=7.69.1
ARG CURL_SHA256="01ae0c123dee45b01bbaef94c0bc00ed2aec89cb2ee0fd598e0d302a6b5e0a98"
RUN apt-get remove curl -y \
  && rm -rf /usr/local/include/curl \
  && cd /usr/local/src \
  && wget "https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz" -O "curl-${CURL_VERSION}.tar.gz" \
  && echo "$CURL_SHA256" "curl-${CURL_VERSION}.tar.gz" | sha256sum -c - \
  && tar -zxvf "curl-${CURL_VERSION}.tar.gz" \
  && cd "curl-${CURL_VERSION}" \
  && CPPFLAGS="-I/usr/local/ssl/include" LDFLAGS="-L${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib" LD_LIBRARY_PATH=${PREFIX}/lib \
   ./configure --prefix=/usr/local/curl --with-ssl=${PREFIX} --with-libssl-prefix=${PREFIX} \
  && make \
  && make install \
  && ln -s /usr/local/curl/bin/curl /usr/bin/curl \
  && rm -rf "/usr/local/src/curl-${CURL_VERSION}.tar.gz" "/usr/local/src/curl-${CURL_VERSION}" 

# Rebuild stunnel
ARG STUNNEL_VERSION=5.59
ARG STUNNEL_SHA256="137776df6be8f1701f1cd590b7779932e123479fb91e5192171c16798815ce9f"
RUN cd /usr/local/src \
  && wget "https://www.stunnel.org/downloads/stunnel-${STUNNEL_VERSION}.tar.gz" -O "stunnel-${STUNNEL_VERSION}.tar.gz" \
  && echo "$STUNNEL_SHA256" "stunnel-${STUNNEL_VERSION}.tar.gz" | sha256sum -c - \
  && tar -zxvf "stunnel-${STUNNEL_VERSION}.tar.gz" \
  && cd "stunnel-${STUNNEL_VERSION}" \
  && CPPFLAGS="-I${PREFIX}/include" LDFLAGS="-L${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib" LD_LIBRARY_PATH=${PREFIX}/lib \
   ./configure --prefix=/usr/local/stunnel --with-ssl=${PREFIX} \
  && make \
  && make install \
  && ln -s /usr/local/stunnel/bin/stunnel /usr/bin/stunnel \
  && rm -rf "/usr/local/src/stunnel-${STUNNEL_VERSION}.tar.gz" "/usr/local/src/stunnel-${STUNNEL_VERSION}"
