#!/bin/bash

_INSTALL(){
  cp /etc/resolv.conf /etc/resolv.conf.bak
  echo -e "nameserver 2a01:4f8:c2c:123f::1\nnameserver 2a00:1098:2c::1\nnameserver 2a01:4f9:c010:3f02::1" > /etc/resolv.conf
  apt update && apt install curl wget sudo vim gnupg lsb-release proxychains4 -y
  echo -n "Enter your domain:"
  read domain
  echo -n "Enter your username:"
  read username
  echo -n "Enter your password:"
  read password
  echo -n "Enter your email:"
  read email
  wget https://github.com/U201413497/v6naiveproxy/releases/download/caddy/caddy
  mv /root/caddy /usr/bin/ && chmod +x /usr/bin/caddy
  mkdir /etc/caddy
  touch /etc/caddy/Caddyfile
  echo ":443, $domain
        tls $email
        route {
          forward_proxy {
            basic_auth $username $password
            hide_ip
            hide_via
            probe_resistance secert.localhost
            upstream socks5://127.0.0.1:8080
                       }
            reverse_proxy https://demo.cloudreve.org {
            header_up Host {upstream_hostport}
            header_up X-Forwarded-Host {host}
                                                     }
             }" > /etc/caddy/Caddyfile
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
  wget https://github.com/U201413497/v6naiveproxy/releases/download/xray/xray
  mv /root/xray /usr/local/bin/ && chmod +x /usr/local/bin/xray
  mkdir /usr/local/etc/xray && touch /usr/local/etc/xray/config.json
  echo "
  {
  "\"inbounds"\": [
    {
      "\"tag"\": "\"socks"\",
      "\"port"\": 8080,
      "\"listen"\": "\"127.0.0.1"\",
      "\"protocol"\": "\"socks"\",
      "\"settings"\": {
          "\"udp"\": true
                  }
    }
  ],
  "\"outbounds"\": [
    { 
      "\"tag"\": "\"outbound-warp"\",
      "\"protocol"\": "\"socks"\",
      "\"settings"\": {
        "\"servers"\": [
          {
            "\"address"\": "\"127.0.0.1"\",
            "\"port"\": 9090
          }
        ]
      }
    },
    {
      "\"tag"\": "\"direct"\",
      "\"protocol"\": "\"freedom"\"
    }
  ],
  "\"routing"\": {
    "\"domainStrategy"\": "\"IPOnDemand"\",
    "\"rules"\": [
      {
        "\"type"\": "\"field"\",
        "\"ip"\": [ "\"::/0"\" ],
        "\"outboundTag"\": "\"direct"\"
      },
      {
        "\"type"\": "\"field"\",
        "\"ip"\": [ "\"0.0.0.0/0"\" ],
        "\"outboundTag"\": "\"outbound-warp"\"
      }
    ]
  }
}" > /usr/local/etc/xray/config.json
  touch /etc/systemd/system/xray.service
  echo "
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/xray.service
  systemctl daemon-reload
  systemctl enable caddy.service xray.service
  curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg |  gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
  apt update && apt install -y cloudflare-warp
  warp-cli register 
  warp-cli set-mode proxy
  warp-cli set-proxy-port 9090
  warp-cli connect
  warp-cli enable-always-on
  curl -Ls https://raw.githubusercontent.com/U201413497/v6naiveproxy/main/proxychains4.conf -o proxychains4.conf
  mv proxychains4.conf /etc/proxychains4.conf
  cp /etc/resolv.conf.bak /etc/resolv.conf
  systemctl start caddy.service xray.service
}

_INSTALL
