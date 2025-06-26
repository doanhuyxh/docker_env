#!/bin/bash

# Set non-interactive mode for apt
export DEBIAN_FRONTEND=noninteractive

# Exit on any error
set -e

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Update and upgrade Ubuntu
echo "Updating and upgrading Ubuntu..."
apt update
apt upgrade -y

# Configure the timezone
echo "Setting timezone to Asia/Ho_Chi_Minh..."
timedatectl set-timezone Asia/Ho_Chi_Minh

# Enable and configure UFW (firewall)
echo "Enabling UFW and allowing SSH (port 22) and MSSQL (port 1433)..."
apt install -y ufw
ufw allow 22/tcp
ufw allow 1433/tcp
ufw --force enable
ufw status


# Install essential tools
echo "Installing git, curl, wget, unzip, unrar, rar, speedtest-cli, and iperf3..."
apt install -y git curl wget unzip unrar rar python3-pip iperf3
pip3 install --no-input speedtest-cli

# Install environments: .NET Core 8.0
echo "Installing .NET Core 8.0..."
if ! dpkg -l | grep -q packages-microsoft-prod; then
    wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
fi
apt update
apt install -y dotnet-sdk-8.0

# Install environments: nvm
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Load nvm for the current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Verify nvm installation
if command -v nvm >/dev/null 2>&1; then
    echo "nvm installed successfully"
else
    echo "nvm installation failed"
    exit 1
fi

# Install auditd for SSH login monitoring
echo "Installing auditd for SSH login monitoring..."
apt install -y auditd
systemctl enable auditd
systemctl start auditd

# Configure SSH logging
echo "Configuring SSH logging..."
sed -i 's/#LogLevel INFO/LogLevel VERBOSE/' /etc/ssh/sshd_config
systemctl restart sshd

# Verify installations
if command -v speedtest-cli >/dev/null 2>&1 && command -v iperf3 >/dev/null 2>&1 && command -v auditctl >/dev/null 2>&1; then
    echo "Network tools and auditd installed successfully"
else
    echo "Installation of network tools or auditd failed"
    exit 1
fi

# Install services: Nginx
echo "Installing Nginx..."
apt install -y nginx
ufw allow 'Nginx HTTP'
ufw allow 'Nginx HTTPS'
systemctl stop nginx
systemctl start nginx
systemctl restart nginx
systemctl reload nginx
systemctl disable nginx
systemctl enable nginx

# Install services: Certbot
echo "Installing Certbot and Nginx plugin..."
apt install -y certbot python3-certbot-nginx

# Install services: Docker
echo "Installing Docker via apt..."
apt remove -y docker docker-engine docker.io containerd runc || true
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl enable containerd
systemctl start docker
usermod -aG docker $SUDO_USER || true

# Verify Docker installation
if ! docker --version; then
    echo "Docker installation failed"
    exit 1
fi
echo "Docker installation successful"

# Install services: MSSQL Server via Docker
echo "Installing MSSQL Server via Docker..."
if ! systemctl is-active --quiet docker; then
    echo "Docker service is not running. Starting Docker..."
    systemctl start docker
fi
docker pull mcr.microsoft.com/mssql/server:2022-latest
mkdir -p /home/csdl_data/mssql
docker run --pull always -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=01882904300Huy@" -e "MSSQL_PID=Evaluation" \
-p 1433:1433 --name sqlpreview -v /home/csdl_data/mssql:/var/opt/mssql -d mcr.microsoft.com/mssql/server:2022-latest

# Install services: MongoDB via Docker
echo "Installing MongoDB via Docker..."
docker pull mongo
mkdir -p /home/csdl_data/mongo
docker run -d --name mongo_database \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=01882904300Huy@ \
  -p 0.0.0.0:27017:27017 \
  -v "/home/csdl_data/mongo:/data/db" \
  mongo

# Display instructions for usage
echo "Network speed test instructions:"
echo "- Run 'speedtest-cli' to test internet speed."
echo "- Run 'iperf3 -s' on one server and 'iperf3 -c <server_ip>' on another to test network bandwidth."
echo "SSH login history instructions:"
echo "- Check recent logins with 'last'."
echo "- Check SSH logs in /var/log/auth.log with 'grep sshd /var/log/auth.log'."
echo "- Check auditd logs with 'ausearch -m USER_LOGIN'."

echo "Setup completed successfully!"