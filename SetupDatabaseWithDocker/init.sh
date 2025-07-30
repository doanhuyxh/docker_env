# set up database with docker
# define the variables and install necessary packages
PASSWORD_DATABASE="01882904300Huy@"
echo "🐳 Cài đặt Docker..."
# check if Docker is already installed
if ! command -v docker &> /dev/null; then
    echo "Docker chưa được cài đặt. Tiến hành cài đặt..."
    # install Docker
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    # ─────────────────────────────────────────────────────────────
    echo "📦 Cài đặt Docker Compose..."
    sudo apt-get install -y docker-compose
    echo "📦 Docker Compose đã được cài đặt thành công."
fi
echo "🐳 Docker đã được cài đặt thành công."
# ─────────────────────────────────────────────────────────────
echo "📦 Cài đặt các volume cần thiết..."
sudo docker volume create db_data_mysql
sudo docker volume create db_data_postgres
sudo docker volume create db_data_mssql
sudo docker volume create db_data_mongodb
sudo docker volume create db_data_redis
sudo docker volume create db_data_elasticsearch
echo "📦 Các volume đã được tạo thành công."
# ─────────────────────────────────────────────────────────────
echo "Cài đặt mạng Docker..."
sudo docker network create docker-app-network
echo "🌐 Mạng Docker đã được tạo thành công."
# ─────────────────────────────────────────────────────────────
echo "🗄️ Cài đặt MySQL 8.0..."
docker pull mysql:8.0
docker run --name mysql-8.0 \
  --network docker-app-network \
  -e MYSQL_ROOT_PASSWORD=$PASSWORD_DATABASE \
  -e MYSQL_ROOT_HOST=% \
  -p 3306:3306 \
  -v db_data_mysql:/var/lib/mysql \
  -d mysql:8.0
echo "🗄️ MySQL 8.0 đã được cài đặt thành công."
# ─────────────────────────────────────────────────────────────
echo "🗄️ Cài đặt PostgreSQL..."
docker pull postgres
docker run --name postgres \
  --network docker-app-network \
  -e POSTGRES_PASSWORD=$PASSWORD_DATABASE \
  -e POSTGRES_USER=admin \
  -p 5432:5432 \
  -v db_data_postgres:/var/lib/postgresql/data \
  -d postgres
echo "🗄️ PostgreSQL đã được cài đặt thành công."
# ─────────────────────────────────────────────────────────────
echo "🗄️ Cài đặt MongoDB..."
docker pull mongo
docker run --name mongodb \
  --network docker-app-network \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=$PASSWORD_DATABASE \
  -p 27017:27017 \
  -v db_data_mongodb:/data/db \
  -d mongo
echo "🗄️ MongoDB đã được cài đặt thành công."
# ─────────────────────────────────────────────────────────────
echo "🗄️ Cài đặt Redis..."
docker pull redis
docker run --name redis \
  --network docker-app-network \
  -e REDIS_PASSWORD=$PASSWORD_DATABASE \
  -p 6379:6379 \
  -v db_data_redis:/data \
  -d redis
echo "🗄️ Redis đã được cài đặt thành công."
# ─────────────────────────────────────────────────────────────
echo "🗄️ Cài đặt Elasticsearch..."
docker pull docker.elastic.co/elasticsearch/elasticsearch:8.0.0
docker run --name elasticsearch \
  --network docker-app-network \
  -e "discovery.type=single-node" \
  -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
  -p 9200:9200 \
  -p 9300:9300 \
  -v db_data_elasticsearch:/usr/share/elasticsearch/data \
  -d docker.elastic.co/elasticsearch/elasticsearch:8.0.0
echo "🗄️ Elasticsearch đã được cài đặt thành công."
# ─────────────────────────────────────────────────────────────
echo "🗄️ Cài đặt MSSQL Server (Docker)..."
docker pull mcr.microsoft.com/mssql/server:2022-latest
docker run -e "ACCEPT_EULA=Y" \
  --network docker-app-network \
  -e MSSQL_SA_PASSWORD=$PASSWORD_DATABASE \
  -e "MSSQL_PID=Developer" \
  -p 0.0.0.0:1433:1433 \
  --name sqlpreview \
  -v db_data_mssql:/var/opt/mssql \
  -d mcr.microsoft.com/mssql/server:2022-latest
echo "🗄️ MSSQL Server đã được cài đặt thành công."
# ─────────────────────────────────────────────────────────────
echo "✅ Tất cả các dịch vụ cơ sở dữ liệu đã được cài đặt thành công!"