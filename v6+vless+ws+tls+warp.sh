#!/bin/bash

_INSTALL(){
  cp /etc/resolv.conf /etc/resolv.conf.bak
  echo -e "nameserver 2a01:4f8:c2c:123f::1\nnameserver 2a00:1098:2c::1\nnameserver 2a01:4f9:c010:3f02::1" > /etc/resolv.conf
  apt update && apt install curl wget sudo vim gnupg lsb-release proxychains4 -y
  bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) --version 4.45.2
  systemctl enable v2ray
  sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg --yes
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
  sudo apt update
  sudo apt install caddy
  systemctl enable caddy
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
  curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg |  gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
  apt update && apt install -y cloudflare-warp
  warp-cli register 
  warp-cli set-mode proxy
  warp-cli set-proxy-port 9090
  warp-cli connect
  warp-cli enable-always-on
  curl -Ls https://raw.githubusercontent.com/U201413497/v6-wap-vless-ws-tls-warp/main/proxychains4.conf -o proxychains4.conf
  mv proxychains4.conf /etc/proxychains4.conf
  cp /etc/resolv.conf.bak /etc/resolv.conf
  service v2ray restart
  service caddy restart
  echo -n "your protocol is vless"
  echo -n "your port is 443"
  echo -n "your domain is $domain"
  echo -n "your path is $path"
  echo -n "your uuid is $uuid"
  echo -n "enjoy it!"
}

_INSTALL
