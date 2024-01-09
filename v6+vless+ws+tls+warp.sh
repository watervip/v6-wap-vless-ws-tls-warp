#!/bin/bash

_INSTALL(){
  cp /etc/resolv.conf /etc/resolv.conf.bak
  echo -e "nameserver 2a01:4f8:c2c:123f::1\nnameserver 2a00:1098:2c::1\nnameserver 2a01:4f9:c010:3f02::1" > /etc/resolv.conf
  apt update && apt install curl wget sudo vim gnupg lsb-release proxychains4 -y
  bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) --version 4.45.2
  systemctl enable v2ray
  wget https://github.com/U201413497/v6-wap-vless-ws-tls-warp/releases/download/caddy/caddy
  mv /root/caddy /usr/bin/ && chmod +x /usr/bin/caddy
  mkdir /etc/caddy
  touch /etc/caddy/Caddyfile
  echo -n "Enter your domain:"
  read domain
  echo -n "Enter your email:"
  read email
  uuid=$(cat /proc/sys/kernel/random/uuid)
  echo -n "Enter your path, without /"
  read path
  cat >/etc/caddy/Caddyfile <<-EOF
$domain
{
    tls $email
    encode gzip
    handle_path /$path {
        reverse_proxy localhost:8888
    }
}
EOF
cat >/usr/local/etc/v2ray/config.json <<-EOF
{ 
    "inbounds": [
        {
            "listen": "127.0.0.1",
            "port": 8888, 
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid", 
                        "level": 1,
                        "alterId": 0
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws"
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        }
    ],
    "outbounds": [
    { 
      "tag": "outbound-warp",
      "protocol": "socks",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": 9090
          }
        ]
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom"
    }
  ],
  "routing": {
    "domainStrategy": "IPOnDemand",
    "rules": [
      {
        "type": "field",
        "ip": [ "::/0" ],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "ip": [ "0.0.0.0/0" ],
        "outboundTag": "outbound-warp"
      }
    ]
  }
}
EOF
touch /etc/systemd/system/caddy.service
  echo "
  [Unit]
  Description=Caddy HTTP/2 web server
  Documentation=https://caddyserver.com/docs
  After=network-online.target
  Wants=network-online.target systemd-networkd-wait-online.service

  [Service]
  ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
  ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
  Restart=always
  RestartPreventExitStatus=23
  AmbientCapabilities=CAP_NET_BIND_SERVICE

  [Install]
  WantedBy=multi-user.target" > /etc/systemd/system/caddy.service
  systemctl daemon-reload
  systemctl enable caddy.service
  curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg |  gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
  apt update && apt install -y cloudflare-warp
  warp-cli register
  sleep 3
  warp-cli set-mode proxy
  sleep 3
  warp-cli set-proxy-port 9090
  sleep 3
  warp-cli connect
  sleep 3
  warp-cli enable-always-on
  curl -Ls https://raw.githubusercontent.com/U201413497/v6-wap-vless-ws-tls-warp/main/proxychains4.conf -o proxychains4.conf
  mv proxychains4.conf /etc/proxychains4.conf
  cp /etc/resolv.conf.bak /etc/resolv.conf
  service v2ray restart
  systemctl start caddy
  echo -n "your link is vless://$uuid@$domain:443?encryption=none&security=tls&type=ws&path=%2F$path#$domain"
}

_INSTALL
