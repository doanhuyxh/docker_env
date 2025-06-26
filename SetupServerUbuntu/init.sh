#!/bin/bash

# Exit on any error
set -e

# Ensure the script is run as root (since many commands require sudo)
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

# Install essential tools
echo "Installing git, curl, wget, unzip, unrar, and rar..."
apt install -y git curl wget unzip unrar rar

# Install Nginx
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

# Install Certbot
echo "Installing Certbot and Nginx plugin..."
apt install -y certbot python3-certbot-nginx

# Install .NET Core 8.0
echo "Installing .NET Core 8.0..."
# Add Microsoft package repository
wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
apt update
apt-get install -y dotnet-sdk-8.0

# Install Docker
echo "Installing Docker..."
snap install docker

# Install MSSQL Server
echo "Installing MSSQL Server via Docker..."
docker pull mcr.microsoft.com/mssql/server:2022-latest
mkdir -p /var/www/csdl_data/mssql
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=01882904300Huy@" -e "MSSQL_PID=Evaluation" \
-p 1433:1433 --name sqlpreview -v /var/www/csdl_data/mssql:/var/opt/mssql -d mcr.microsoft.com/mssql/server:2022-latest

# Install nvm (Node Version Manager)
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Load nvm for the current session (non-persistent)
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

echo "Setup completed successfully!"