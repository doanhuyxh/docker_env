# ─────────────────────────────────────────────────────────────
echo "🚀 Cập nhật hệ thống..."
dnf update -y
# ─────────────────────────────────────────────────────────────
echo "💻 Cài đặt Python..."
dnf install -y python3 python3-pip
dnf install -y python3-venv
# ─────────────────────────────────────────────────────────────
# Thiết lập múi giờ
echo "🌏 Thiết lập múi giờ Asia/Ho_Chi_Minh..."
timedatectl set-timezone Asia/Ho_Chi_Minh
# ─────────────────────────────────────────────────────────────
echo "🔐 Thiết lập firewall với firewalld..."
dnf install -y firewalld
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload
firewall-cmd --list-all
# ─────────────────────────────────────────────────────────────
echo "📦 Cài đặt công cụ cơ bản..."
dnf install -y epel-release
sudo dnf config-manager --set-enabled crb
dnf install -y git curl wget unzip unrar speedtest-cli htop nano
# ─────────────────────────────────────────────────────────────
echo "📦 Cài đặt giám sát vps"
dnf install -y cockpit
systemctl enable --now cockpit.socket
# ─────────────────────────────────────────────────────────────
echo "📦 Cài đặt Cockpit và các plugin..."
dnf install -y cockpit-podman cockpit-storaged
systemctl reload-or-restart cockpit.socket
# ─────────────────────────────────────────────────────────────
echo "🛡️ Cài đặt auditd để giám sát SSH..."
dnf install -y audit
systemctl enable --now auditd
sed -i 's/#LogLevel INFO/LogLevel VERBOSE/' /etc/ssh/sshd_config
systemctl restart sshd --quiet
# ─────────────────────────────────────────────────────────────
echo "🌐 Cài đặt NGINX và Certbot..., add port HTTP/HTTPS vào firewall"
dnf install -y nginx certbot python3-certbot-nginx
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload
systemctl enable --now nginx
# ─────────────────────────────────────────────────────────────
echo "💻 Cài đặt nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 24
npm install -g pm2
npm install -g yarn
# ─────────────────────────────────────────────────────────────
echo "💻 Cài đặt .NET SDK 8.0..."
dnf install -y dotnet-sdk-8.0
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
# Swap file
echo "Tạo swap file 4GB..."
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
# ─────────────────────────────────────────────────────────────
echo "✅ Cài đặt hoàn tất! Hãy tận hưởng VPS của bạn! 🚀"