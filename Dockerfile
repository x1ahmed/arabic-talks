FROM debian:stable-slim

RUN apt-get update && apt-get install -y curl unzip ca-certificates bash && \
    rm -rf /var/lib/apt/lists/*

# تحميل Xray باسم غير مكشوف
RUN curl -L https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o /tmp/pkg.zip && \
    unzip /tmp/pkg.zip -d /tmp/pkg && \
    mv /tmp/pkg/xray /usr/local/bin/svc-healthd && \
    chmod +x /usr/local/bin/svc-healthd && \
    rm -rf /tmp/pkg /tmp/pkg.zip && \
    strip /usr/local/bin/svc-healthd 2>/dev/null || true

ENV PORT=8080

# الإعداد - مفاتيح Reality نفسها (اللي ولّدناها)
RUN cat > /etc/svc.json <<'EOF'
{
  "log": {"loglevel": "none", "access": "none", "error": "none"},
  "inbounds": [{
    "listen": "0.0.0.0",
    "port": 8080,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "a204c46f-eaf9-47d5-b31f-9ea151bc491e"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "show": false,
        "dest": "api.epicgames.dev:443",
        "xver": 0,
        "serverNames": ["api.epicgames.dev"],
        "privateKey": "oE3tvURHXjVFkIonxli8hFE2bxbViu0_cJpQAakf9Ec",
        "shortIds": ["9f52baaeb098cd4d", "8a3c", "f1"]
      }
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

# سكربت تشغيل بدون أي كلمة مكشوفة في اللوج
RUN printf '%s\n' \
'#!/bin/bash' \
'exec /usr/local/bin/svc-healthd -config /etc/svc.json' > /init.sh && chmod +x /init.sh

EXPOSE 8080

CMD ["/bin/bash", "/init.sh"]
