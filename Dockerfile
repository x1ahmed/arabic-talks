FROM node:20-alpine

RUN apk add --no-cache curl unzip ca-certificates > /dev/null 2>&1

WORKDIR /app

RUN curl -sL "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip" -o tmp.zip && \
    unzip -q tmp.zip && \
    mv xray /app/server && \
    chmod +x /app/server && \
    rm -f tmp.zip geoip.dat geosite.dat LICENSE README.md

RUN echo '{"name":"analytics-service","version":"2.1.0","private":true}' > /app/package.json

ENV UUID=8442ff27-8e79-4f27-b4d2-c3e6447789ea
ENV WS_PATH=/api/v1/stream
ENV PORT=8080
ENV SNI=gpubgm.com

RUN printf '%s\n' \
    '#!/bin/sh' \
    'DOMAIN=${RAILWAY_PUBLIC_DOMAIN:-"localhost"}' \
    'cat > /app/cfg.json <<EOC' \
    '{' \
    '  "log": {"loglevel": "none"},' \
    '  "inbounds": [{' \
    '    "port": '${PORT}',' \
    '    "protocol": "vless",' \
    '    "settings": {"clients": [{"id": "'${UUID}'"}], "decryption": "none"},' \
    '    "streamSettings": {"network": "ws", "wsSettings": {"path": "'${WS_PATH}'"}}' \
    '  }],' \
    '  "outbounds": [{"protocol": "freedom"}]' \
    '}' \
    'EOC' \
    'exec -a node /app/server -config /app/cfg.json' \
    > /app/bootstrap.sh && chmod +x /app/bootstrap.sh

EXPOSE 8080

CMD ["/bin/sh", "/app/bootstrap.sh"]
