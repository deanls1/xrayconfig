function changeXrayConfig() {
  echo "change xray config"
  rm -rf /usr/local/etc/xray/config.json
  wget -O /usr/local/etc/xray/config.json "https://drive.google.com/uc?export=download&id=1LZJKqA_Ks9BIsla7aW5roFL7Pmqq_1os"
}
function installNginx() {
  echo "install Nginx"
  apt-get update && apt install nginx
  systemctl enable nginx.service && systemctl start nginx.service && rm -rf /etc/nginx/nginx.conf
  wget -O /etc/nginx/nginx.conf "https://drive.google.com/uc?export=download&id=17_Ee6c1uQ89E3ySjnq4Mt0sUcb3te6wk"
}

function installCert() {
  echo "install Cert"
  apt update && apt install snapd && snap install core && sudo snap refresh core && snap install --classic certbot && ln -s /snap/bin/certbot /usr/bin/certbot
}
echo "install xray"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root
if [ $? == 0 ]
then
  echo "install xray success"
  apt install wget
  changeXrayConfig
  installNginx
  installCert
  certbot certonly --preferred-challenges dns --manual  -d *.deanls.top --server https://acme-v02.api.letsencrypt.org/directory
  echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
  sysctl -p
  lsmod | grep bbr
  systemctl restart xray
else
  echo "fail to install xray"
  exit 8
fi
