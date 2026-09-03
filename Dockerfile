FROM debian:stable-slim

# تثبيت الأدوات الأساسية وخادم Caddy للتمويه
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    bash \
    tar \
    && rm -rf /var/lib/apt/lists/*

# تحميل وتثبيت Xray-core
RUN bash -c "curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o xray.zip && \
    unzip xray.zip && \
    mv xray /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && \
    rm -rf xray.zip"

# تحميل وتثبيت خادم Caddy التمويهي
RUN bash -c "curl -sL 'https://github.com/caddyserver/caddy/releases/download/v2.8.4/caddy_2.8.4_linux_amd64.tar.gz' | tar -xz -C /usr/local/bin caddy && \
    chmod +x /usr/local/bin/caddy"

# المتغيرات الافتراضية (مسار مخفي يظهر كأنه API)
ENV UUID=8442ff27-8e79-4f27-b4d2-c3e6447789ea
ENV WS_PATH=/api/v3/telemetry/stream
ENV PORT=8080
ENV SNI=gpubgm.com

# إنشاء سكربت التشغيل مع الموقع التمويهي وإعدادات Caddy & Xray
RUN cat << 'EOF' > /start.sh
#!/bin/bash

PORT=${PORT:-8080}
UUID=${UUID:-"8442ff27-8e79-4f27-b4d2-c3e6447789ea"}
WS_PATH=${WS_PATH:-"/api/v3/telemetry/stream"}
DOMAIN=${RAILWAY_PUBLIC_DOMAIN:-"your-app.up.railway.app"}
SNI=${SNI:-"$DOMAIN"}

mkdir -p /var/www/html /etc/xray /etc/caddy

# 1. إنشاء موقع ويب تمويهي حقيقي (Fake Webpage)
cat << 'EOC' > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>API Gateway Status</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f4f6f9; color: #333; text-align: center; padding: 80px 20px; }
        .card { background: #fff; max-width: 480px; margin: 0 auto; padding: 40px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
        h1 { color: #2c3e50; font-size: 22px; margin-bottom: 10px; }
        p { color: #666; font-size: 14px; line-height: 1.5; }
        .status { display: inline-block; padding: 6px 14px; background: #e8f8f5; color: #27ae60; border-radius: 20px; font-weight: 600; font-size: 13px; margin-bottom: 15px; }
    </style>
</head>
<body>
    <div class="card">
        <span class="status">● All Systems Operational</span>
        <h1>Microservice Gateway</h1>
        <p>This node is actively routing REST API endpoints and telemetry microservices.</p>
    </div>
</body>
</html>
EOC

# 2. إعداد ملف إعدادات Xray (يعمل محلياً فقط)
cat << EOC > /etc/xray/config.json
{
  "log": { "loglevel": "none" },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10080,
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "${UUID}" }],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${WS_PATH}"
        }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOC

# 3. إعداد ملف Caddy لتمرير حركة المرور
cat << EOC > /etc/caddy/Caddyfile
:${PORT} {
    root * /var/www/html
    file_server

    @vless_path {
        path ${WS_PATH}
    }
    reverse_proxy @vless_path 127.0.0.1:10080
}
EOC

# تشغيل Xray في الخلفية
xray -config /etc/xray/config.json &

# طباعة الرابط المخفي
echo "---------------------------------------------------------------"
echo "STEALTH VLESS LINK:"
echo "vless://${UUID}@${DOMAIN}:443?path=${WS_PATH//\//%2F}&security=tls&encryption=none&type=ws&sni=${SNI}#Railway-Stealth"
echo "---------------------------------------------------------------"

# تشغيل Caddy كعملية رئيسية
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
EOF

RUN chmod +x /start.sh

# فتح البورت
EXPOSE $PORT

# تشغيل السكربت
CMD ["/bin/bash", "/start.sh"]
