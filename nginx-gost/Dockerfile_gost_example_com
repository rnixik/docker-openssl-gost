FROM rnix/nginx-gost

COPY gen_demo_gost_certs.sh /
RUN chmod +x /gen_demo_gost_certs.sh
RUN /gen_demo_gost_certs.sh
COPY gost.conf /etc/nginx/nginx.conf
