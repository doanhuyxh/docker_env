#!/bin/bash

# ─────────────────────────────────────────────────────────────
# CÀI ĐẶT MÔI TRƯỜNG CHO VPS (Ubuntu) - BẢN TỰ ĐỘNG HOÀN TOÀN
# Bao gồm: UFW, Docker, .NET 8, MSSQL, MongoDB, Nginx, v.v...
# ─────────────────────────────────────────────────────────────

# Cấu hình ban đầu
set -e
export DEBIAN_FRONTEND=noninteractive

# Kiểm tra root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Vui lòng chạy script với quyền root (sudo)"
  exit 1
fi

# Biến cấu hình
MSSQL_IMAGE="mcr.microsoft.com/mssql/server:2022-latest"
MSSQL_PASSWORD="01882904300Huy@"
MONGO_PASSWORD="01882904300Huy@"
DATA_DIR="/home/csdl_data"

# ─────────────────────────────────────────────────────────────
echo "🚀 Cập nhật hệ thống..."
apt update && apt upgrade -y

# Thiết lập múi giờ
echo "🌏 Thiết lập múi giờ Asia/Ho_Chi_Minh..."
timedatectl set-timezone Asia/Ho_Chi_Minh

# ─────────────────────────────────────────────────────────────
echo "🔐 Thiết lập firewall với UFW..."
apt install -y ufw
ufw allow 22/tcp
ufw allow 1433/tcp
ufw allow 27017/tcp
ufw --force enable
ufw status

# ─────────────────────────────────────────────────────────────
echo "📦 Cài đặt công cụ cơ bản..."
apt install -y git curl wget unzip unrar rar iperf3 python3-pip
pip3 install --no-input speedtest-cli

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

# ─────────────────────────────────────────────────────────────
echo "🛡️ Cài đặt auditd để giám sát SSH..."
apt install -y auditd
systemctl enable --now auditd
sed -i 's/#LogLevel INFO/LogLevel VERBOSE/' /etc/ssh/sshd_config
systemctl restart sshd

# ─────────────────────────────────────────────────────────────
echo "🌐 Cài đặt NGINX và Certbot..."
apt install -y nginx certbot python3-certbot-nginx
systemctl enable --now nginx
ufw allow 'Nginx HTTP'
ufw allow 'Nginx HTTPS'
# ─────────────────────────────────────────────────────────────
echo "🐳 Cài đặt Docker..."
apt remove -y docker docker-engine docker.io containerd runc || true
apt install -y apt-transport-https ca-certificates gnupg lsb-release curl
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable --now docker
usermod -aG docker $SUDO_USER || true

# Tạo Docker network nếu chưa tồn tại
NETWORK_NAME="docker-app-network"
docker network create $NETWORK_NAME 2>/dev/null || true

# ─────────────────────────────────────────────────────────────
echo "🗄️ Cài đặt MSSQL Server (Docker)..."
mkdir -p "$DATA_DIR/mssql"
docker rm -f sqlpreview 2>/dev/null || true
docker pull "$MSSQL_IMAGE"
echo "🧠 RAM ${TOTAL_RAM_MB}MB > 2GB → dùng bản Express"
docker run --pull always \
    --network $NETWORK_NAME \
    -e "ACCEPT_EULA=Y" \
    -e "MSSQL_SA_PASSWORD=$MSSQL_PASSWORD" \
    -e "MSSQL_PID=Express" \
    -p 0.0.0.0:1433:1433 \
    --name sqlpreview \
    -v "$DATA_DIR/mssql":/var/opt/mssql \
    -d "$MSSQL_IMAGE"

# ─────────────────────────────────────────────────────────────
echo "🍃 Cài đặt MongoDB (Docker)..."
mkdir -p "$DATA_DIR/mongo"
docker rm -f mongo_database 2>/dev/null || true
docker pull mongo
docker run -d --name mongo_database \
  --network $NETWORK_NAME \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=$MONGO_PASSWORD \
  -p 0.0.0.0:27017:27017 \
  -v "$DATA_DIR/mongo:/data/db" \
  mongo

# ─────────────────────────────────────────────────────────────
echo "✅ Thiết lập hoàn tất!"

echo "
📡 Kiểm tra tốc độ mạng:
- speedtest-cli

📊 Kiểm tra băng thông:
- iperf3 -s (server)
- iperf3 -c <IP> (client)

🔐 Xem lịch sử SSH:
- last
- grep sshd /var/log/auth.log
- ausearch -m USER_LOGIN
"

