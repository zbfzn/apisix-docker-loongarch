FROM cr.loongnix.cn/library/alpine:3.11 as pre-build

ARG APISIX_DASHBOARD_VERSION="2.15.1"

RUN set -x \
    && apk add --no-cache --virtual .builddeps git \
    && if [ "$ENABLE_PROXY" = "true" ]; then git clone --depth 1 --branch v${APISIX_DASHBOARD_VERSION} https://cf.ghproxy.cc/https://github.com/apache/apisix-dashboard.git /usr/local/apisix-dashboard ; \
      else git clone --depth 1 --branch v${APISIX_DASHBOARD_VERSION} https://github.com/apache/apisix-dashboard.git /usr/local/apisix-dashboard ; fi \
    && cd /usr/local/apisix-dashboard && git clean -Xdf \
    && rm -f ./.githash && git log --pretty=format:"%h" -1 > ./.githash



FROM --platform=linux/amd64 apache/apisix-dashboard:2.15.1-alpine as web-static



FROM cr.loongnix.cn/library/golang:1.19-buster as api-builder

ARG ENABLE_PROXY=true

WORKDIR /usr/local/apisix-dashboard

COPY --from=pre-build /usr/local/apisix-dashboard .

RUN if [ "$ENABLE_PROXY" = "true" ] ; then go env -w GOPROXY=https://goproxy.cn,direct ; fi \
    && go env -w GO111MODULE=on \
    && CGO_ENABLED=0 ./api/build.sh



FROM cr.loongnix.cn/library/alpine:3.11 as prod

WORKDIR /usr/local/apisix-dashboard

COPY --from=api-builder /usr/local/apisix-dashboard/output/ ./
COPY --from=web-static /usr/local/apisix-dashboard/conf ./
COPY --from=web-static /usr/local/apisix-dashboard/dag-to-lua ./
COPY --from=web-static /usr/local/apisix-dashboard/html ./

RUN mkdir logs

EXPOSE 9000

CMD [ "/usr/local/apisix-dashboard/manager-api" ]


