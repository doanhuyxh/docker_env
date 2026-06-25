#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────
echo "Check OS"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "OS: $NAME $VERSION"
else
    echo "❌ Không thể xác định hệ thống."
    exit 1
fi
sleep 2
echo "Check Package manager"
if [ "$ID" = "ubuntu" ]; then
    export DEBIAN_FRONTEND=noninteractive
    PKG_MGR="apt"
else
    PKG_MGR="dnf"
fi
echo "Package manager: $PKG_MGR"
sleep 2
# ─────────────────────────────────────────────────────────────
echo "🚀 Cập nhật hệ thống..."
if [ "$PKG_MGR" = "apt" ]; then
    apt update -y
else
    dnf update -y
fi
# ─────────────────────────────────────────────────────────────
# Swap file
echo "Tạo swap file 4GB..."
if [ ! -f /swapfile ]; then
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    echo "✅ Swap file đã được tạo thành công."
else
    echo "✅ Swap file đã tồn tại."
fi
sleep 2
# ─────────────────────────────────────────────────────────────
PACKAGES=(
    nano
    htop
    net-tools
    wget
    curl
    git
    unzip
    unrar
    speedtest-cli
)

echo "Cài đặt hệ thống"
if [ "$PKG_MGR" = "apt" ]; then
    apt install -y "${PACKAGES[@]}"
else
    dnf install -y epel-release
    dnf install -y "${PACKAGES[@]}"
fi
echo "✅ Hệ thống đã được cài đặt thành công."
sleep 2
# ─────────────────────────────────────────────────────────────
echo "Cài đặt docker"
if [ "$PKG_MGR" = "apt" ]; then
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update -y
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
else
    dnf install -y dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi
systemctl enable --now docker
# ─────────────────────────────────────────────────────────────
echo "Cài đặt docker compose"
docker compose version
# ─────────────────────────────────────────────────────────────
echo "Cài nginx container"
mkdir -p /home/nginx
cat > /home/nginx/docker-compose.yml <<'EOF'
services:
  app:
    image: 'jc21/nginx-proxy-manager:2.15.1'
    restart: unless-stopped
    environment:
      TZ: "Asia/Ho_Chi_Minh"
    network_mode: host
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOF
mkdir -p /home/nginx/data /home/nginx/letsencrypt
cd /home/nginx && docker compose up -d
echo "✅ Nginx Proxy Manager đã được cài đặt thành công."
# ─────────────────────────────────────────────────────────────
echo "Setup Firewall"
if [ "$PKG_MGR" = "apt" ]; then
    echo "🔐 Thiết lập firewall với UFW..."
    apt install -y ufw
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 81/tcp
    ufw allow 443/tcp
    ufw --force enable
    ufw status
else
    echo "🔐 Thiết lập firewall với firewalld..."
    dnf install -y firewalld
    systemctl enable firewalld
    systemctl start firewalld
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-port=80/tcp
    firewall-cmd --permanent --add-port=81/tcp
    firewall-cmd --permanent --add-port=443/tcp
    firewall-cmd --reload
    firewall-cmd --list-all
fi
sleep 2
# ─────────────────────────────────────────────────────────────
echo "✅ Hệ thống đã được cài đặt thành công."