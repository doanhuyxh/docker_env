#Update and upgrade
apt update
apt upgrade -y

# Install Docker
snap install docker

# Configure the timezone
timedatectl set-timezone Asia/Ho_Chi_Minh

# Install Nginx
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
apt install Certbot
sudo apt install certbot python3-certbot-nginx


# Install .NET Core 8.0
apt-get install -y dotnet-sdk-8.0


# Install MSSQL Server
docker pull mcr.microsoft.com/mssql/server:2022-latest
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=01882904300Huy@" -e "MSSQL_PID=Evaluation" -p 1433:1433 --name sqlpreview -d mcr.microsoft.com/mssql/server:2022-latest


# Install other tools
apt install -y git
apt install -y curl
apt install -y wget
apt install -y unzip
apt install -y unrar
apt install -y rar