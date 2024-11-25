FROM cr.loongnix.cn/openresty/openresty:1.21.4.1

WORKDIR /home
ARG APISIX_VERSION="2.15.3"

COPY 0001-fix-remove-jit-on-loongarch64-fix-error-usr-local-ap.patch ./

RUN set -x \
    && apk add bash shadow gnupg ca-certificates curl git gcc g++ make cmake pcre-dev openldap-dev \
    && git clone --depth 1 --branch ${APISIX_VERSION} https://cf.ghproxy.cc/https://github.com/apache/apisix.git apisix-${APISIX_VERSION} \
    && cd apisix-${APISIX_VERSION} \
    && git apply ../0001-fix-remove-jit-on-loongarch64-fix-error-usr-local-ap.patch \
    && make deps ENV_INST_LUADIR=/usr/local/apisix \
    && make install ENV_INST_LUADIR=/usr/local/apisix \
    && mkdir -p /usr/local/apisix/ \
    && cp -r deps/ /usr/local/apisix/ \
    && cd ../ \
    && rm -rf apisix-${APISIX_VERSION} 0001-fix-remove-jit-on-loongarch64-fix-error-usr-local-ap.patch ./


WORKDIR /usr/local/apisix

ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin


# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /usr/local/apisix/logs/access.log \
    && ln -sf /dev/stderr /usr/local/apisix/logs/error.log

EXPOSE 9080 9443

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["docker-start"]


STOPSIGNAL SIGQUIT