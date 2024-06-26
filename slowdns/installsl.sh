#!/bin/bash

GIT_CMD="https://github.com/FighterTunnel/tunnel/raw/main/"
ns_domain_cloudflare() {
touch /etc/nsdomain/dns
DOMAIN="smr88.online"
DAOMIN=$(cat /etc/xray/domain)
SUB=$(tr </dev/urandom -dc a-z0-9 | head -c7)
SUB_DOMAIN=${SUB}."smr88.online"
NS_DOMAIN=${SUB_DOMAIN}
CF_ID=buwung07@gmail.com
CF_KEY=03f49404223cb1a6b6f05db51213e518aba9c
set -euo pipefail
IP=$(wget -qO- ipinfo.io/ip)
echo "Updating DNS NS for ${NS_DOMAIN}..."
ZONE=$(
curl -sLX GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}&status=active" \
-H "X-Auth-Email: ${CF_ID}" \
-H "X-Auth-Key: ${CF_KEY}" \
-H "Content-Type: application/json" | jq -r .result[0].id
)
RECORD=$(
curl -sLX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?name=${NS_DOMAIN}" \
-H "X-Auth-Email: ${CF_ID}" \
-H "X-Auth-Key: ${CF_KEY}" \
-H "Content-Type: application/json" | jq -r .result[0].id
)
if [[ "${#RECORD}" -le 10 ]]; then
RECORD=$(
curl -sLX POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
-H "X-Auth-Email: ${CF_ID}" \
-H "X-Auth-Key: ${CF_KEY}" \
-H "Content-Type: application/json" \
--data '{"type":"NS","name":"'${NS_DOMAIN}'","content":"'${DAOMIN}'","proxied":false}' | jq -r .result.id
)
fi
RESULT=$(
curl -sLX PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${RECORD}" \
-H "X-Auth-Email: ${CF_ID}" \
-H "X-Auth-Key: ${CF_KEY}" \
-H "Content-Type: application/json" \
--data '{"type":"NS","name":"'${NS_DOMAIN}'","content":"'${DAOMIN}'","proxied":false}'
)
echo $NS_DOMAIN >/etc/nsdomain/dns
}
ns_domain_cloudflare
setup_dnstt() {
cd /root
mkdir -p /etc/slowdns
wget -O dnstt-server "${GIT_CMD}X-SlowDNS/dnstt-server" && chmod +x dnstt-server >/dev/null 2>&1
wget -O dnstt-client "${GIT_CMD}X-SlowDNS/dnstt-client" && chmod +x dnstt-client >/dev/null 2>&1
./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub
chmod +x *
mv dnstt-server /etc/slowdns/
mv dnstt-client /etc/slowdns/
mv server.pub /etc/slowdns/
mv server.key /etc/slowdns/
wget -O /etc/systemd/system/client.service "${GIT_CMD}X-SlowDNS/client" >/dev/null 2>&1
wget -O /etc/systemd/system/server.service "${GIT_CMD}X-SlowDNS/server" >/dev/null 2>&1
sed -i "s/xxxx/$NS_DOMAIN/g" /etc/systemd/system/client.service
sed -i "s/xxxx/$NS_DOMAIN/g" /etc/systemd/system/server.service
}
setup_dnstt
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
iptables-save >/etc/iptables/rules.v4 >/dev/null 2>&1
iptables-save >/etc/iptables.up.rules >/dev/null 2>&1
netfilter-persistent save >/dev/null 2>&1
netfilter-persistent reload >/dev/null 2>&1
systemctl enable iptables >/dev/null 2>&1
systemctl start iptables >/dev/null 2>&1
systemctl restart iptables >/dev/null 2>&1
