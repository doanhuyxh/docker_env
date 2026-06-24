# ─────────────────────────────────────────────────────────────
echo "🚀 Cập nhật hệ thống..."
dnf update -y
# ─────────────────────────────────────────────────────────────
# Swap file
echo "Tạo swap file 4GB..."
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
# ─────────────────────────────────────────────────────────────
echo "Cài đặt docker"
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
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
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOF
mkdir -p /home/nginx/data /home/nginx/letsencrypt
cd /home/nginx && docker compose up -d
echo "✅ Nginx Proxy Manager đã được cài đặt thành công."
# ─────────────────────────────────────────────────────────────
echo "Setup Firewall"
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
# ─────────────────────────────────────────────────────────────