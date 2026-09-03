FROM node:20-alpine

# تثبيت الأدوات بصمت (صورة Node أقل شكاً من Debian)
RUN apk add --no-cache curl unzip ca-certificates > /dev/null 2>&1

WORKDIR /app

# تحميل Xray وإعادة تسميته لشيء عادي + تنظيف الملفات الزائدة
RUN curl -sL "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip" -o tmp.zip && \
    unzip -q tmp.zip && \
    mv xray /app/server && \
    chmod +x /app/server && \
    rm -f tmp.zip xray geoip.dat geosite.dat LICENSE README.md

# ملف package.json وهمي (يظهر في file system كـ Node.js app)
RUN echo '{"name":"analytics-service","version":"2.1.0","description":"Real-time data processor","main":"server.js","private":true}' > /app/package.json && \
    echo 'node_modules/' > /app/.gitignore && \
    echo 'dist/' >> /app/.gitignore

ENV UUID=8442ff27-8e79-4f27-b4d2-c3e6447789ea
ENV WS_PATH=/api/v1/stream
ENV PORT=8080
ENV SNI=gpubgm.com

# بناء السكربت بدون أي طباعة مشبوهة في الـ Logs
RUN printf '%s\n' \
    '#!/bin/sh' \
    'DOMAIN=${RAILWAY_PUBLIC_DOMAIN:-"localhost"}' \
    '' \
    '# كتابة الإعدادات بهدوء' \
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
    '' \
    '# تشغيل الـ binary باسم "node" (procname camouflage)' \
    'exec -a node /app/server -config /app/cfg.json' \
    > /app/bootstrap.sh && chmod +x /app/bootstrap.sh

EXPOSE 8080

CMD ["/bin/sh", "/app/bootstrap.sh"]
