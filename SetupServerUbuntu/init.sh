#!/bin/bash

# ─────────────────────────────────────────────────────────────
# CÀI ĐẶT MÔI TRƯỜNG CHO VPS (Ubuntu) - BẢN TỰ ĐỘNG HOÀN TOÀN
# Bao gồm: UFW, Docker, .NET 8, MSSQL, MongoDB, Nginx, v.v...
# ─────────────────────────────────────────────────────────────

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

# Biến cấu hình
MSSQL_IMAGE="mcr.microsoft.com/mssql/server:2022-latest"
MSSQL_PASSWORD="01882904300Huy@"
MONGO_PASSWORD="01882904300Huy@"
DATA_DIR="/home/csdl_data"

# ─────────────────────────────────────────────────────────────
echo "🚀 Cập nhật hệ thống..."
apt update -y

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
apt install -y git curl wget unzip unrar rar iperf3 python3-pip speedtest-cli

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

# ─────────────────────────────────────────────────────────────
echo "🛡️ Cài đặt auditd để giám sát SSH..."
apt install -y auditd
systemctl enable --now auditd
sed -i 's/#LogLevel INFO/LogLevel VERBOSE/' /etc/ssh/sshd_config
systemctl restart sshd --quiet

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

apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable --now docker
usermod -aG docker $SUDO_USER || true

# Tạo Docker network nếu chưa tồn tại
NETWORK_NAME="docker-app-network"
docker network create $NETWORK_NAME 2>/dev/null || true

# ─────────────────────────────────────────────────────────────
echo "🗄️ Kiểm tra cấu hình để cài đặt MSSQL Server..."

# Kiểm tra RAM
TOTAL_RAM_MB=$(free -m | awk 'NR==2{print $2}')
TOTAL_RAM_GB=$((TOTAL_RAM_MB / 1024))
echo "🧠 RAM hiện tại: ${TOTAL_RAM_MB}MB (${TOTAL_RAM_GB}GB)"

# Kiểm tra dung lượng đĩa
DISK_AVAILABLE_GB=$(df -BG /home | awk 'NR==2 {print $4}' | sed 's/G//')
echo "💾 Dung lượng đĩa khả dụng: ${DISK_AVAILABLE_GB}GB"

# Kiểm tra CPU cores
CPU_CORES=$(nproc)
echo "⚡ CPU cores: ${CPU_CORES}"

# Điều kiện tối thiểu cho MSSQL:
# - RAM: tối thiểu 2GB (khuyến nghị 4GB+)
# - Disk: tối thiểu 6GB cho cài đặt
# - CPU: tối thiểu 1 core (khuyến nghị 2+ cores)

if [ "$TOTAL_RAM_MB" -lt 2048 ]; then
    echo "❌ RAM không đủ cho MSSQL Server (cần tối thiểu 2GB, hiện tại: ${TOTAL_RAM_MB}MB)"
    echo "⏭️ Bỏ qua cài đặt MSSQL Server"
elif [ "$DISK_AVAILABLE_GB" -lt 6 ]; then
    echo "❌ Dung lượng đĩa không đủ cho MSSQL Server (cần tối thiểu 6GB, hiện tại: ${DISK_AVAILABLE_GB}GB)"
    echo "⏭️ Bỏ qua cài đặt MSSQL Server"
else
    echo "✅ Cấu hình đủ điều kiện để cài đặt MSSQL Server"
    echo "🗄️ Cài đặt MSSQL Server (Docker)..."
    
    mkdir -p "$DATA_DIR/mssql"
    sudo chown -R 10001:0 "$DATA_DIR/mssql"
    sudo chmod -R 770 "$DATA_DIR/mssql"
    docker rm -f sqlpreview 2>/dev/null || true
    docker pull "$MSSQL_IMAGE"
    
    # Chọn phiên bản phù hợp với RAM
    if [ "$TOTAL_RAM_MB" -lt 4096 ]; then
        echo "🧠 RAM ${TOTAL_RAM_MB}MB < 4GB → dùng bản Express"
        MSSQL_PID="Express"
    else
        echo "🧠 RAM ${TOTAL_RAM_MB}MB ≥ 4GB → dùng bản Developer"
        MSSQL_PID="Developer"
    fi
    
    docker run --pull always \
        --network $NETWORK_NAME \
        -e "ACCEPT_EULA=Y" \
        -e "MSSQL_SA_PASSWORD=$MSSQL_PASSWORD" \
        -e "MSSQL_PID=$MSSQL_PID" \
        -p 0.0.0.0:1433:1433 \
        --name sqlpreview \
        -v "$DATA_DIR/mssql":/var/opt/mssql:z \
        -d "$MSSQL_IMAGE"
        
    echo "✅ MSSQL Server đã được cài đặt thành công!"
    echo "🔗 Kết nối: localhost:1433"
    echo "👤 Username: sa"
    echo "🔑 Password: $MSSQL_PASSWORD"
fi

# ─────────────────────────────────────────────────────────────
echo "🍃 Cài đặt MongoDB (Docker)..."
mkdir -p "$DATA_DIR/mongo"
sudo chown -R 10001:0 "$DATA_DIR/mongo"
sudo chmod -R 770 "$DATA_DIR/mongo"
docker rm -f mongo_database 2>/dev/null || true
docker pull mongo
docker run -d --name mongo_database \
  --network $NETWORK_NAME \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=$MONGO_PASSWORD \
  -p 0.0.0.0:27017:27017 \
  -v "$DATA_DIR/mongo":/data/db:z \
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

