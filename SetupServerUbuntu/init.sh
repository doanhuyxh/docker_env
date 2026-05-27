#!/bin/bash
# Cấu hình ban đầu
set -e
export DEBIAN_FRONTEND=noninteractive
# Tự động trả lời Yes cho tất cả câu hỏi
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1
# Vô hiệu hóa các câu hỏi tương tác
export UCF_FORCE_CONFFOLD=1
export APT_LISTCHANGES_FRONTEND=none
# Tự động khởi động lại dịch vụ không cần xác nhận
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
# Kiểm tra root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Vui lòng chạy script với quyền root (sudo)"
  exit 1
fi
# ─────────────────────────────────────────────────────────────
echo "🚀 Cập nhật hệ thống..."
apt update -y
# ─────────────────────────────────────────────────────────────
# Tạo swapfile 4GB nếu chưa tồn tại
if [ ! -f /swapfile ]; then
  echo "💾 Tạo swapfile 4GB..."
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
fi
# ─────────────────────────────────────────────────────────────
# Cài đặt needrestart với cấu hình tự động
echo "🔄 Cài đặt needrestart để tự động khởi động lại dịch vụ..."
apt install -y needrestart
echo "\$nrconf{restart} = 'a';" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{kernelhints} = 0;" >> /etc/needrestart/needrestart.conf

# Thiết lập múi giờ
echo "🌏 Thiết lập múi giờ Asia/Ho_Chi_Minh..."
timedatectl set-timezone Asia/Ho_Chi_Minh
# ─────────────────────────────────────────────────────────────
echo "🔐 Thiết lập firewall với UFW..."
apt install -y ufw
ufw allow 22/tcp
ufw --force enable
ufw status

# ─────────────────────────────────────────────────────────────
echo "📦 Cài đặt công cụ cơ bản..."
apt install -y git curl wget unzip unrar rar python3-pip python3-venv speedtest-cli

# ─────────────────────────────────────────────────────────────
echo "📦 Cài đặt giám sát vps"
apt install -y cockpit
systemctl enable --now cockpit.socket

# ─────────────────────────────────────────────────────────────
echo "📦 Cài đặt Cockpit và các plugin..."
apt install -y cockpit-podman cockpit-storaged
systemctl reload-or-restart cockpit.socket

# ─────────────────────────────────────────────────────────────
echo "💻 Cài đặt .NET SDK 8.0..."
wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb
apt update && apt install -y dotnet-sdk-8.0

# ─────────────────────────────────────────────────────────────
echo "🧠 Cài đặt NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
source "$NVM_DIR/bash_completion"
nvm install 24
npm install -g pm2
npm install -g yarn
# ─────────────────────────────────────────────────────────────
echo "🛡️ Cài đặt auditd để giám sát SSH..."
apt install -y auditd
systemctl enable --now auditd
sed -i 's/#LogLevel INFO/LogLevel VERBOSE/' /etc/ssh/sshd_config
if systemctl list-unit-files | grep -q '^ssh.service'; then
  systemctl restart ssh --quiet
elif systemctl list-unit-files | grep -q '^sshd.service'; then
  systemctl restart sshd --quiet
else
  echo "⚠️ Không tìm thấy service ssh/sshd, vui lòng kiểm tra thủ công."
fi

# ─────────────────────────────────────────────────────────────
echo "🌐 Cài đặt NGINX và Certbot..."
apt install -y nginx certbot python3-certbot-nginx
systemctl enable --now nginx
ufw allow 'Nginx HTTP'
ufw allow 'Nginx HTTPS'
# ─────────────────────────────────────────────────────────────
echo "🐳 Cài đặt Docker..."
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin