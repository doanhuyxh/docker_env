#!/bin/bash
# Script cài đặt database với Docker - Có thể chọn database cần cài
# define the variables and install necessary packages
PASSWORD_DATABASE="01882904300Huy@"

# Danh sách database có thể cài đặt
declare -A databases=(
    ["mysql"]="MySQL 8.0"
    ["postgres"]="PostgreSQL"
    ["mongodb"]="MongoDB"
    ["redis"]="Redis"
    ["elasticsearch"]="Elasticsearch"
    ["mssql"]="MSSQL Server"
)

# Function kiểm tra container đã tồn tại
check_container_exists() {
    local container_name=$1
    if docker ps -a --format 'table {{.Names}}' | grep -q "^${container_name}$"; then
        return 0
    else
        return 1
    fi
}

# Function hiển thị trạng thái containers
show_container_status() {
    echo "� Kiểm tra trạng thái các container database hiện tại:"
    echo "─────────────────────────────────────────────────────────────"
    
    for key in "${!databases[@]}"; do
        case $key in
            "mysql")
                if check_container_exists "mysql-8.0"; then
                    status=$(docker ps --format 'table {{.Names}}\t{{.Status}}' | grep "mysql-8.0" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ $//')
                    if [ -n "$status" ]; then
                        echo "✅ MySQL 8.0: $status"
                    else
                        echo "⚠️  MySQL 8.0: Container tồn tại nhưng đã dừng"
                    fi
                else
                    echo "❌ MySQL 8.0: Chưa được cài đặt"
                fi
                ;;
            "postgres")
                if check_container_exists "postgres"; then
                    status=$(docker ps --format 'table {{.Names}}\t{{.Status}}' | grep "postgres" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ $//')
                    if [ -n "$status" ]; then
                        echo "✅ PostgreSQL: $status"
                    else
                        echo "⚠️  PostgreSQL: Container tồn tại nhưng đã dừng"
                    fi
                else
                    echo "❌ PostgreSQL: Chưa được cài đặt"
                fi
                ;;
            "mongodb")
                if check_container_exists "mongodb"; then
                    status=$(docker ps --format 'table {{.Names}}\t{{.Status}}' | grep "mongodb" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ $//')
                    if [ -n "$status" ]; then
                        echo "✅ MongoDB: $status"
                    else
                        echo "⚠️  MongoDB: Container tồn tại nhưng đã dừng"
                    fi
                else
                    echo "❌ MongoDB: Chưa được cài đặt"
                fi
                ;;
            "redis")
                if check_container_exists "redis"; then
                    status=$(docker ps --format 'table {{.Names}}\t{{.Status}}' | grep "redis" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ $//')
                    if [ -n "$status" ]; then
                        echo "✅ Redis: $status"
                    else
                        echo "⚠️  Redis: Container tồn tại nhưng đã dừng"
                    fi
                else
                    echo "❌ Redis: Chưa được cài đặt"
                fi
                ;;
            "elasticsearch")
                if check_container_exists "elasticsearch"; then
                    status=$(docker ps --format 'table {{.Names}}\t{{.Status}}' | grep "elasticsearch" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ $//')
                    if [ -n "$status" ]; then
                        echo "✅ Elasticsearch: $status"
                    else
                        echo "⚠️  Elasticsearch: Container tồn tại nhưng đã dừng"
                    fi
                else
                    echo "❌ Elasticsearch: Chưa được cài đặt"
                fi
                ;;
            "mssql")
                if check_container_exists "sqlpreview"; then
                    status=$(docker ps --format 'table {{.Names}}\t{{.Status}}' | grep "sqlpreview" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/ $//')
                    if [ -n "$status" ]; then
                        echo "✅ MSSQL Server: $status"
                    else
                        echo "⚠️  MSSQL Server: Container tồn tại nhưng đã dừng"
                    fi
                else
                    echo "❌ MSSQL Server: Chưa được cài đặt"
                fi
                ;;
        esac
    done
    echo "─────────────────────────────────────────────────────────────"
}

# Function hiển thị menu chọn database
show_database_menu() {
    echo ""
    echo "📋 Chọn database cần cài đặt:"
    echo "─────────────────────────────────────────────────────────────"
    echo "1) MySQL 8.0"
    echo "2) PostgreSQL"
    echo "3) MongoDB"
    echo "4) Redis"
    echo "5) Elasticsearch"
    echo "6) MSSQL Server"
    echo "7) Cài đặt tất cả"
    echo "0) Thoát"
    echo "─────────────────────────────────────────────────────────────"
}

# Function cài đặt Docker
install_docker() {
    echo "�🐳 Cài đặt Docker..."
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
}

# Function tạo volume và network
setup_docker_infrastructure() {
    echo "📦 Thiết lập cơ sở hạ tầng Docker..."
    
    # Tạo network nếu chưa tồn tại
    if ! docker network ls | grep -q "docker-app-network"; then
        echo "Tạo mạng Docker..."
        docker network create docker-app-network
        echo "🌐 Mạng Docker đã được tạo thành công."
    else
        echo "🌐 Mạng Docker đã tồn tại."
    fi
}

# Function tạo volume cho database cụ thể
create_volume_for_db() {
    local db_type=$1
    case $db_type in
        "mysql")
            if ! docker volume ls | grep -q "db_data_mysql"; then
                docker volume create db_data_mysql
                echo "📦 Volume MySQL đã được tạo."
            fi
            ;;
        "postgres")
            if ! docker volume ls | grep -q "db_data_postgres"; then
                docker volume create db_data_postgres
                echo "📦 Volume PostgreSQL đã được tạo."
            fi
            ;;
        "mongodb")
            if ! docker volume ls | grep -q "db_data_mongodb"; then
                docker volume create db_data_mongodb
                echo "📦 Volume MongoDB đã được tạo."
            fi
            ;;
        "redis")
            if ! docker volume ls | grep -q "db_data_redis"; then
                docker volume create db_data_redis
                echo "📦 Volume Redis đã được tạo."
            fi
            ;;
        "elasticsearch")
            if ! docker volume ls | grep -q "db_data_elasticsearch"; then
                docker volume create db_data_elasticsearch
                echo "📦 Volume Elasticsearch đã được tạo."
            fi
            ;;
        "mssql")
            if ! docker volume ls | grep -q "db_data_mssql"; then
                docker volume create db_data_mssql
                echo "📦 Volume MSSQL đã được tạo."
            fi
            ;;
    esac
}

# Function cài đặt MySQL
install_mysql() {
    if check_container_exists "mysql-8.0"; then
        echo "⚠️  Container MySQL đã tồn tại. Bỏ qua cài đặt."
        return
    fi
    
    echo "🗄️ Cài đặt MySQL 8.0..."
    create_volume_for_db "mysql"
    docker pull mysql:8.0
    docker run --name mysql-8.0 \
      --network docker-app-network \
      -e MYSQL_ROOT_PASSWORD=$PASSWORD_DATABASE \
      -e MYSQL_ROOT_HOST=% \
      -p 3306:3306 \
      -v db_data_mysql:/var/lib/mysql \
      -d mysql:8.0
    echo "🗄️ MySQL 8.0 đã được cài đặt thành công."
}

# Function cài đặt PostgreSQL
install_postgres() {
    if check_container_exists "postgres"; then
        echo "⚠️  Container PostgreSQL đã tồn tại. Bỏ qua cài đặt."
        return
    fi
    
    echo "🗄️ Cài đặt PostgreSQL..."
    create_volume_for_db "postgres"
    docker pull postgres
    docker run --name postgres \
      --network docker-app-network \
      -e POSTGRES_PASSWORD=$PASSWORD_DATABASE \
      -e POSTGRES_USER=admin \
      -p 5432:5432 \
      -v db_data_postgres:/var/lib/postgresql/data \
      -d postgres
    echo "🗄️ PostgreSQL đã được cài đặt thành công."
}

# Function cài đặt MongoDB
install_mongodb() {
    if check_container_exists "mongodb"; then
        echo "⚠️  Container MongoDB đã tồn tại. Bỏ qua cài đặt."
        return
    fi
    
    echo "🗄️ Cài đặt MongoDB..."
    create_volume_for_db "mongodb"
    docker pull mongo
    docker run --name mongodb \
      --network docker-app-network \
      -e MONGO_INITDB_ROOT_USERNAME=admin \
      -e MONGO_INITDB_ROOT_PASSWORD=$PASSWORD_DATABASE \
      -p 27017:27017 \
      -v db_data_mongodb:/data/db \
      -d mongo
    echo "🗄️ MongoDB đã được cài đặt thành công."
}

# Function cài đặt Redis
install_redis() {
    if check_container_exists "redis"; then
        echo "⚠️  Container Redis đã tồn tại. Bỏ qua cài đặt."
        return
    fi
    
    echo "🗄️ Cài đặt Redis..."
    create_volume_for_db "redis"
    docker pull redis
    docker run --name redis \
      --network docker-app-network \
      -e REDIS_PASSWORD=$PASSWORD_DATABASE \
      -p 6379:6379 \
      -v db_data_redis:/data \
      -d redis
    echo "🗄️ Redis đã được cài đặt thành công."
}

# Function cài đặt Elasticsearch
install_elasticsearch() {
    if check_container_exists "elasticsearch"; then
        echo "⚠️  Container Elasticsearch đã tồn tại. Bỏ qua cài đặt."
        return
    fi
    
    echo "🗄️ Cài đặt Elasticsearch..."
    create_volume_for_db "elasticsearch"
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
}

# Function cài đặt MSSQL Server
install_mssql() {
    if check_container_exists "sqlpreview"; then
        echo "⚠️  Container MSSQL Server đã tồn tại. Bỏ qua cài đặt."
        return
    fi
    
    echo "🗄️ Cài đặt MSSQL Server (Docker)..."
    create_volume_for_db "mssql"
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
}

# Function cài đặt tất cả database
install_all_databases() {
    echo "🚀 Cài đặt tất cả database..."
    install_mysql
    install_postgres
    install_mongodb
    install_redis
    install_elasticsearch
    install_mssql
    echo "✅ Tất cả các dịch vụ cơ sở dữ liệu đã được cài đặt thành công!"
}

# Main script
echo "🔧 Script cài đặt Database với Docker"
echo "====================================="

# Cài đặt Docker trước
install_docker

# Thiết lập cơ sở hạ tầng Docker
setup_docker_infrastructure

# Hiển thị trạng thái hiện tại
show_container_status

# Menu chính
while true; do
    show_database_menu
    read -p "Nhập lựa chọn của bạn (0-7): " choice
    
    case $choice in
        1)
            install_mysql
            ;;
        2)
            install_postgres
            ;;
        3)
            install_mongodb
            ;;
        4)
            install_redis
            ;;
        5)
            install_elasticsearch
            ;;
        6)
            install_mssql
            ;;
        7)
            install_all_databases
            ;;
        0)
            echo "👋 Thoát script. Cảm ơn bạn đã sử dụng!"
            exit 0
            ;;
        *)
            echo "❌ Lựa chọn không hợp lệ. Vui lòng chọn từ 0-7."
            ;;
    esac
    
    echo ""
    read -p "Nhấn Enter để tiếp tục..."
    echo ""
done

