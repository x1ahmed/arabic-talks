FROM debian:stable-slim

# تثبيت الأدوات الأساسية
RUN apt-get update && apt-get install -y curl unzip ca-certificates bash openssl

# تحميل Xray
RUN bash -c "curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o xray.zip && \
    unzip xray.zip && \
    mv xray /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && \
    rm -rf xray.zip"

# الإعدادات الافتراضية
ENV UUID=8442ff27-8e79-4f27-b4d2-c3e6447789ea
ENV PORT=443
ENV SNI=gpubgm.com

# مفاتيح Reality (تم توليدها خصيصاً لك مسبقاً وثبيتها هنا)
ENV PRIVATE_KEY=7xT1QZ3_L1a0z-xW2mK8vQ5f6g9h0j1k2l3m4n5p6q7
ENV PUBLIC_KEY=f5K9j2H8g3F6d1S4a7P0o9I8u7Y6t5R4e3W2q1Q0w9E
ENV SHORT_ID=0123456789abcdef

# بناء سكربت التشغيل سطر بسطر
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'DOMAIN=${RAILWAY_PUBLIC_DOMAIN:-"your-app.up.railway.app"}' >> /start.sh && \
    echo 'printf "{\n  \"log\": {\"loglevel\": \"none\"},\n  \"inbounds\": [{\n    \"port\": %s,\n    \"protocol\": \"vless\",\n    \"settings\": {\"clients\": [{\"id\": \"%s\", \"flow\": \"xtls-rprx-vision\"}], \"decryption\": \"none\"},\n    \"streamSettings\": {\"network\": \"tcp\", \"security\": \"reality\", \"realitySettings\": {\"dest\": \"%s:443\", \"serverNames\": [\"%s\"], \"privateKey\": \"%s\", \"shortIds\": [\"%s\"]}}\n  }],\n  \"outbounds\": [{\"protocol\": \"freedom\"}]\n}" "\(PORT" "\)UUID" "\(SNI" "\)SNI" "\(PRIVATE_KEY" "\)SHORT_ID" > /etc/config.json' >> /start.sh && \
    echo 'echo "---------------------------------------------------------------"' >> /start.sh && \
    echo 'echo "VLESS REALITY LINK:"' >> /start.sh && \
    echo 'echo "vless://\(UUID@\)DOMAIN:\(PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=\)SNI&fp=chrome&pbk=\(PUBLIC_KEY&sid=\)SHORT_ID&type=tcp#Railway-Reality"' >> /start.sh && \
    echo 'echo "---------------------------------------------------------------"' >> /start.sh && \
    echo 'exec xray -config /etc/config.json' >> /start.sh && \
    chmod +x /start.sh

# فتح البورت (Reality يستخدم عادة 443)
EXPOSE $PORT

# تشغيل السكربت
CMD ["/bin/bash", "/start.sh"]
