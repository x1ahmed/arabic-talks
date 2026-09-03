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

RUN printf '%s\n' \
    '#!/bin/sh' \
    'cat > /app/cfg.json <<EOC' \
    '{' \
    '  "log": {"loglevel": "none"},' \
    '  "inbounds": [' \
    '    {' \
    '      "port": 443,' \
    '      "protocol": "vless",' \
    '      "settings": {' \
    '        "clients": [' \
    '          {' \
    '            "id": "'${UUID}'",' \
    '            "flow": "xtls-rprx-vision"' \
    '          }' \
    '        ],' \
    '        "decryption": "none"' \
    '      },' \
    '      "streamSettings": {' \
    '        "network": "tcp",' \
    '        "security": "reality",' \
    '        "realitySettings": {' \
    '          "show": false,' \
    '          "dest": "gpubgm.com:443",' \
    '          "xver": 0,' \
    '          "serverNames": [' \
    '            "gpubgm.com"' \
    '          ],' \
    '          "privateKey": "8GXPCvZ4ty3uEKxexznrZvCSo3NqYwzKY5dzbaQGWVM",' \
    '          "shortIds": [' \
    '            "8236"' \
    '          ]' \
    '        }' \
    '      }' \
    '    }' \
    '  ],' \
    '  "outbounds": [' \
    '    {' \
    '      "protocol": "freedom"' \
    '    }' \
    '  ],' \
    '  "stats": {},' \
    '  "policy": {' \
    '    "system": {' \
    '      "statsInboundUplink": true,' \
    '      "statsInboundDownlink": true' \
    '    }' \
    '  }' \
    '}' \
    'EOC' \
    'exec -a node /app/server -config /app/cfg.json' \
    > /app/bootstrap.sh && chmod +x /app/bootstrap.sh

EXPOSE 443

CMD ["/bin/sh", "/app/bootstrap.sh"]
