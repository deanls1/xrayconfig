function changeXrayConfig() {
  rm -rf /usr/local/etc/xray/config.json
  wget -O /usr/local/etc/xray/config.json "https://drive.google.com/uc?export=download&id=1F9QpIKERjoUg0wa8CfXDlvCLk13WaL3a"
  id=$(xray uuid)
  str='"id": "'"$id"'",'
  sed -i '13 i \\t\t\t            '"$str"''  /usr/local/etc/xray/config.json 
  read -p "input servername: " sn
  str2='"serverName": "'"$sn"'",'
  sed -i '34 i \\t\t            '"$str2"''  /usr/local/etc/xray/config.json
  echo $str
}
function installNginx() {
  apt-get -y update && apt -y install nginx
  systemctl enable nginx.service && systemctl start nginx.service && rm -rf /etc/nginx/nginx.conf
  wget -O /etc/nginx/nginx.conf "https://drive.google.com/uc?export=download&id=12sxkIu5rTuROfVrZolLhRN3sc5emEvxv"
  read -p "input servername: " sn
  str='server_name  '"$sn"';'
  sed -i '64 i \\t\t'"$str"''  /etc/nginx/nginx.conf
  sed -i '71 i \\t\t'"$str"''  /etc/nginx/nginx.conf
  return 0
}

function installCert() {
  apt -y update && apt -y install snapd && snap install core && sudo snap refresh core && snap install --classic certbot && ln -s /snap/bin/certbot /usr/bin/certbot
  return 0
}
function optimizing_system() {
  sed -i '/fs.file-max/d' /etc/sysctl.conf
  sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf
  sed -i '/net.ipv4.route.gc_timeout/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_synack_retries/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_syn_retries/d' /etc/sysctl.conf
  sed -i '/net.core.somaxconn/d' /etc/sysctl.conf
  sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf
  sed -i '/net.ipv4.tcp_max_orphans/d' /etc/sysctl.conf
  sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
  echo "fs.file-max = 1000000
fs.inotify.max_user_instances = 8192
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 32768
# forward ipv4
net.ipv4.ip_forward = 1" >>/etc/sysctl.conf
  sysctl -p
  echo "*               soft    nofile           1000000
*               hard    nofile          1000000" >/etc/security/limits.conf
  echo "ulimit -SHn 1000000" >>/etc/profile
  echo -e "\033[31m your uuid $1 $2 \033[0m"
  if [ $3==0 ];then
    echo "nginx success"
  else
    echo "nginx fail"
  fi
  if [ $4==0 ];then
    echo "cert success"
  else
    echo "cert fail"
  fi
  if [ $5==0 ];then
    echo "bbr success"
  else
    echo "bbr fail"
  fi

  # echo "your uuid $1 $2 "
  read -p "需要重启VPS后，才能生效系统优化配置，是否现在重启 ? [Y/n] :" yn
  [ -z "${yn}" ] && yn="y"
  if [[ $yn == [Yy] ]]; then
    echo -e "${Info} VPS 重启中..."
    reboot
  fi
}
function bbr() {
  echo "net.core.default_qdisc=fq" >>/etc/sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.conf
  sysctl -p
  lsmod | grep bbr
  return 0
}
echo "install xray"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root
if [ $? == 0 ]; then
  echo "install xray success"
  apt -y install wget
  myuuid=$(changeXrayConfig)
  nginxstatus=$(installNginx)
  certstatus=$(installCert)
  certbot certonly --preferred-challenges dns --manual -d *.deanls.top --server https://acme-v02.api.letsencrypt.org/directory
  bbrstatus=$(bbr)
  systemctl restart xray
  # echo "your uuid : $myuuid "
  optimizing_system $myuuid $nginxstatus $certstatus $bbrstatus
else
  echo "fail to install xray"
  exit 8
fi
