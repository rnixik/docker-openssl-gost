#!/bin/bash

DOCKER_BASE_URL="https://raw.githubusercontent.com/docker-library/php/master/7.1/jessie/fpm"
DOCKER_BUILD_FILES=( Dockerfile docker-php-entrypoint docker-php-ext-configure docker-php-ext-enable docker-php-ext-install docker-php-source)
for FILE in "${DOCKER_BUILD_FILES[@]}"
do
  wget -O "${FILE}" "${DOCKER_BASE_URL}/${FILE}"
done

ORIGINAL_INSTRUCTION="FROM debian:jessie"

STAGE_INSTRUCTIONS=$(cat << END
FROM rnix/openssl-gost AS openssl-gost

${ORIGINAL_INSTRUCTION}

COPY --from=openssl-gost /usr/local/ssl /usr/local/ssl
COPY --from=openssl-gost /usr/local/ssl/bin/openssl /usr/bin/openssl
COPY --from=openssl-gost /usr/local/curl /usr/local/curl
COPY --from=openssl-gost /usr/local/curl/bin/curl /usr/bin/curl
COPY --from=openssl-gost /usr/local/bin/gostsum /usr/local/bin/gostsum
COPY --from=openssl-gost /usr/local/bin/gost12sum /usr/local/bin/gost12sum

# pkgconfig is used to compile php
COPY --from=openssl-gost /usr/local/ssl/lib/pkgconfig/* /usr/lib/x86_64-linux-gnu/pkgconfig/
COPY --from=openssl-gost /usr/local/curl/lib/pkgconfig/* /usr/lib/x86_64-linux-gnu/pkgconfig/

END
)

# Change line-endings to set of special characters
STAGE_INSTRUCTIONS=$(echo "${STAGE_INSTRUCTIONS}" | tr '\n' "!")
STAGE_INSTRUCTIONS=$(echo "${STAGE_INSTRUCTIONS}" | sed -e "s/!/~~~/g")

sed -i "s|${ORIGINAL_INSTRUCTION}|${STAGE_INSTRUCTIONS}|" Dockerfile

# Change special charactes back to line-endings
sed -i "s|~~~|\n|g" Dockerfile

# Custom directories
sed -i "s|--with-openssl |--with-openssl --with-openssl-dir=/usr/local/ssl |g" Dockerfile
sed -i "s|--with-curl |--with-curl=/usr/local/curl |g" Dockerfile

# Disable installing dev-packages
sed -i "s|libcurl4-openssl-dev | |g" Dockerfile
sed -i "s|libssl-dev | |g" Dockerfile

# Enable new versions again after apt-get
echo "COPY --from=openssl-gost /usr/local/ssl/bin/openssl /usr/bin/openssl" >> Dockerfile
echo "COPY --from=openssl-gost /usr/local/curl/bin/curl /usr/bin/curl" >> Dockerfile

sed -i 's|GENERATED VIA "update.sh"|GENERATED VIA "update.sh" AND UPDATED VIA openssl-gost|g' Dockerfile
