v6-wap-vless-ws-tls-warp

本脚本旨在wap.ac的年付1刀香港小鸡搭建vless+ws+tls，同时配合warp，出口IPv4流量，IPv6出口依旧是小鸡本身。搭建成功后可以在cloudflare开启小云朵。实现你本地没有IPv6也能成功使用代理。

wap.ac家的1刀年付hk小鸡搭建vless+ws+tls+warp脚本,debian11测试通过

搭建过程需要你输入域名，连接使用；邮箱，申请ssl证书使用；路径，ws时的参数，注意不要带/

apt update && apt install -y curl && bash <(curl -Ls https://raw.githubusercontent.com/U201413497/v6-wap-vless-ws-tls-warp/main/v6+vless+ws+tls+warp.sh)
