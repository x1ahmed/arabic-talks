FROM debian:stable-slim

# تثبيت الأدوات الأساسية وسيرفر Nginx للتمويه
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    bash \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# تحميل النواة وتغيير اسم البرنامج إلى اسم تمويهي (web-engine)
RUN bash -c "curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o engine.zip && \
    unzip engine.zip && \
    mv xray /usr/local/bin/web-engine && \
    chmod +x /usr/local/bin/web-engine && \
    rm -rf engine.zip geoip.dat geosite.dat README.md LICENSE"

# المتغيرات الافتراضية بأسماء ومسارات تمويهية
ENV UUID=8442ff27-8e79-4f27-b4d2-c3e6447789ea
ENV WS_PATH=/api/v3/telemetry
ENV PORT=8080

# بناء سكربت التشغيل التمويهي
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'DOMAIN=${RAILWAY_PUBLIC_DOMAIN:-"your-app.up.railway.app"}' >> /start.sh && \
    # 1. إعداد Nginx كواجهة تمويهية
    echo 'cat << EOF > /etc/nginx/sites-available/default' >> /start.sh && \
    echo 'server {' >> /start.sh && \
    echo '    listen ${PORT};' >> /start.sh && \
    echo '    server_name _;' >> /start.sh && \
    echo '    location / {' >> /start.sh && \
    echo '        default_type application/json;' >> /start.sh && \
    echo '        return 200 "{\"status\":\"healthy\",\"service\":\"api-gateway\",\"version\":\"2.1.0\"}";' >> /start.sh && \
    echo '    }' >> /start.sh && \
    echo '    location ${WS_PATH} {' >> /start.sh && \
    echo '        proxy_redirect off;' >> /start.sh && \
    echo '        proxy_pass http://127.0.0.1:10085;' >> /start.sh && \
    echo '        proxy_http_version 1.1;' >> /start.sh && \
    echo '        proxy_set_header Upgrade \$http_upgrade;' >> /start.sh && \
    echo '        proxy_set_header Connection "upgrade";' >> /start.sh && \
    echo '        proxy_set_header Host \$host;' >> /start.sh && \
    echo '        proxy_set_header X-Real-IP \$remote_addr;' >> /start.sh && \
    echo '    }' >> /start.sh && \
    echo '}' >> /start.sh && \
    echo 'EOF' >> /start.sh && \
    # 2. إعداد ملف إعدادات الخادم الداخلي
    echo 'printf "{\n  \"log\": {\"loglevel\": \"none\"},\n  \"inbounds\": [{\n    \"listen\": \"127.0.0.1\",\n    \"port\": 10085,\n    \"protocol\": \"vless\",\n    \"settings\": {\"clients\": [{\"id\": \"%s\"}], \"decryption\": \"none\"},\n    \"streamSettings\": {\"network\": \"ws\", \"wsSettings\": {\"path\": \"%s\"}}\n  }],\n  \"outbounds\": [{\"protocol\": \"freedom\"}]\n}" "$UUID" "$WS_PATH" > /etc/app_config.json' >> /start.sh && \
    # 3. تشغيل Nginx
    echo 'nginx' >> /start.sh && \
    # 4. تشفير الرابط بـ Base64 لمنع الماسحات الضوئية من اكتشاف VLESS
    echo 'RAW_LINK="vless://$UUID@$DOMAIN:443?path=${WS_PATH//\//%2F}&security=tls&encryption=none&type=ws&sni=$DOMAIN#Railway-App"' >> /start.sh && \
    echo 'B64_LINK=$(echo -n "$RAW_LINK" | base64 -w 0)' >> /start.sh && \
    echo 'echo "==============================================================="' >> /start.sh && \
    echo 'echo " [SUCCESS] System Service Started Successfully."' >> /start.sh && \
    echo 'echo " Config (Base64 Encoded - Decode to get full VLESS link):"' >> /start.sh && \
    echo 'echo "$B64_LINK"' >> /start.sh && \
    echo 'echo "==============================================================="' >> /start.sh && \
    # 5. تشغيل المحرك المخفي
    echo 'exec web-engine -config /etc/app_config.json' >> /start.sh && \
    chmod +x /start.sh

# فتح المنفذ
EXPOSE $PORT

# تشغيل الخدمة
CMD ["/bin/bash", "/start.sh"]
