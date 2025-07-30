#!/bin/bash

# set up database with docker
# define the variables and install necessary packages
PASSWORD_DATABASE="01882904300Huy@"

# Function to install Docker
install_docker() {
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
}

# Function to create volumes and network
setup_infrastructure() {
    echo "📦 Cài đặt các volume cần thiết..."
    sudo docker volume create db_data_mysql 2>/dev/null || echo "Volume db_data_mysql đã tồn tại"
    sudo docker volume create db_data_postgres 2>/dev/null || echo "Volume db_data_postgres đã tồn tại"
    sudo docker volume create db_data_mssql 2>/dev/null || echo "Volume db_data_mssql đã tồn tại"
    sudo docker volume create db_data_mongodb 2>/dev/null || echo "Volume db_data_mongodb đã tồn tại"
    sudo docker volume create db_data_redis 2>/dev/null || echo "Volume db_data_redis đã tồn tại"
    sudo docker volume create db_data_elasticsearch 2>/dev/null || echo "Volume db_data_elasticsearch đã tồn tại"
    echo "📦 Các volume đã được tạo thành công."
    # ─────────────────────────────────────────────────────────────
    echo "Cài đặt mạng Docker..."
    sudo docker network create docker-app-network 2>/dev/null || echo "Mạng docker-app-network đã tồn tại"
    echo "🌐 Mạng Docker đã được tạo thành công."
}

# Function to install MySQL
install_mysql() {
    echo "🗄️ Cài đặt MySQL 8.0..."
    # Remove existing container if exists
    docker stop mysql-8.0 2>/dev/null || true
    docker rm mysql-8.0 2>/dev/null || true
    
    docker pull mysql:8.0
    docker run --name mysql-8.0 \
      --network docker-app-network \
      -e MYSQL_ROOT_PASSWORD=$PASSWORD_DATABASE \
      -e MYSQL_ROOT_HOST=% \
      -p 3306:3306 \
      -v db_data_mysql:/var/lib/mysql \
      -d mysql:8.0
    echo "🗄️ MySQL 8.0 đã được cài đặt thành công."
    echo "   Cổng: 3306"
    echo "   Username: root"
    echo "   Password: $PASSWORD_DATABASE"
}

# Function to install PostgreSQL
install_postgresql() {
    echo "🗄️ Cài đặt PostgreSQL..."
    # Remove existing container if exists
    docker stop postgres 2>/dev/null || true
    docker rm postgres 2>/dev/null || true
    
    docker pull postgres
    docker run --name postgres \
      --network docker-app-network \
      -e POSTGRES_PASSWORD=$PASSWORD_DATABASE \
      -e POSTGRES_USER=admin \
      -p 5432:5432 \
      -v db_data_postgres:/var/lib/postgresql/data \
      -d postgres
    echo "🗄️ PostgreSQL đã được cài đặt thành công."
    echo "   Cổng: 5432"
    echo "   Username: admin"
    echo "   Password: $PASSWORD_DATABASE"
}

# Function to install MongoDB
install_mongodb() {
    echo "🗄️ Cài đặt MongoDB..."
    # Remove existing container if exists
    docker stop mongodb 2>/dev/null || true
    docker rm mongodb 2>/dev/null || true
    
    docker pull mongo
    docker run --name mongodb \
      --network docker-app-network \
      -e MONGO_INITDB_ROOT_USERNAME=admin \
      -e MONGO_INITDB_ROOT_PASSWORD=$PASSWORD_DATABASE \
      -p 27017:27017 \
      -v db_data_mongodb:/data/db \
      -d mongo
    echo "🗄️ MongoDB đã được cài đặt thành công."
    echo "   Cổng: 27017"
    echo "   Username: admin"
    echo "   Password: $PASSWORD_DATABASE"
}

# Function to install Redis
install_redis() {
    echo "🗄️ Cài đặt Redis..."
    # Remove existing container if exists
    docker stop redis 2>/dev/null || true
    docker rm redis 2>/dev/null || true
    
    docker pull redis
    docker run --name redis \
      --network docker-app-network \
      -p 6379:6379 \
      -v db_data_redis:/data \
      -d redis redis-server --requirepass $PASSWORD_DATABASE
    echo "🗄️ Redis đã được cài đặt thành công."
    echo "   Cổng: 6379"
    echo "   Password: $PASSWORD_DATABASE"
}

# Function to install Elasticsearch
install_elasticsearch() {
    echo "🗄️ Cài đặt Elasticsearch..."
    # Remove existing container if exists
    docker stop elasticsearch 2>/dev/null || true
    docker rm elasticsearch 2>/dev/null || true
    
    docker pull docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    docker run --name elasticsearch \
      --network docker-app-network \
      -e "discovery.type=single-node" \
      -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
      -e "xpack.security.enabled=false" \
      -p 9200:9200 \
      -p 9300:9300 \
      -v db_data_elasticsearch:/usr/share/elasticsearch/data \
      -d docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    echo "🗄️ Elasticsearch đã được cài đặt thành công."
    echo "   Cổng: 9200, 9300"
    echo "   URL: http://localhost:9200"
}

# Function to install MSSQL Server
install_mssql() {
    echo "🗄️ Cài đặt MSSQL Server (Docker)..."
    # Remove existing container if exists
    docker stop sqlpreview 2>/dev/null || true
    docker rm sqlpreview 2>/dev/null || true
    
    docker pull mcr.microsoft.com/mssql/server:2022-latest
    docker run -e "ACCEPT_EULA=Y" \
      --network docker-app-network \
      -e MSSQL_SA_PASSWORD=$PASSWORD_DATABASE \
      -e "MSSQL_PID=Developer" \
      -p 1433:1433 \
      --name sqlpreview \
      -v db_data_mssql:/var/opt/mssql \
      -d mcr.microsoft.com/mssql/server:2022-latest
    echo "🗄️ MSSQL Server đã được cài đặt thành công."
    echo "   Cổng: 1433"
    echo "   Username: sa"
    echo "   Password: $PASSWORD_DATABASE"
}

# Function to install all databases
install_all() {
    echo "🚀 Bắt đầu cài đặt tất cả databases..."
    install_mysql
    echo ""
    install_postgresql
    echo ""
    install_mongodb
    echo ""
    install_redis
    echo ""
    install_elasticsearch
    echo ""
    install_mssql
    echo ""
    echo "✅ Tất cả các dịch vụ cơ sở dữ liệu đã được cài đặt thành công!"
}

# Function to show menu
show_menu() {
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    🗄️  DATABASE SETUP MENU                ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  1. 🐳 Cài đặt Docker & Infrastructure                     ║"
    echo "║  2. 🗄️  MySQL 8.0                                         ║"
    echo "║  3. 🐘 PostgreSQL                                          ║"
    echo "║  4. 🍃 MongoDB                                             ║"
    echo "║  5. 🔴 Redis                                               ║"
    echo "║  6. 🔍 Elasticsearch                                       ║"
    echo "║  7. 💾 Microsoft SQL Server                                ║"
    echo "║  8. 🚀 Cài đặt tất cả databases                            ║"
    echo "║  9. 📋 Xem trạng thái containers                           ║"
    echo "║ 10. 🛑 Dừng tất cả containers                              ║"
    echo "║ 11. 🗑️  Xóa tất cả containers                              ║"
    echo "║  0. ❌ Thoát                                               ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# Function to check container status
check_status() {
    echo "📋 Trạng thái các containers:"
    echo "─────────────────────────────────────────────"
    if command -v docker &> /dev/null; then
        docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(mysql-8.0|postgres|mongodb|redis|elasticsearch|sqlpreview)" || echo "Không có container nào đang chạy"
    else
        echo "Docker chưa được cài đặt"
    fi
    echo ""
    read -p "Nhấn Enter để tiếp tục..."
}

# Function to stop all containers
stop_all() {
    echo "🛑 Dừng tất cả containers..."
    docker stop mysql-8.0 postgres mongodb redis elasticsearch sqlpreview 2>/dev/null || true
    echo "✅ Đã dừng tất cả containers"
    read -p "Nhấn Enter để tiếp tục..."
}

# Function to remove all containers
remove_all() {
    echo "🗑️  Xóa tất cả containers..."
    read -p "Bạn có chắc chắn muốn xóa tất cả containers? (y/N): " confirm
    if [[ $confirm == [yY] ]]; then
        docker stop mysql-8.0 postgres mongodb redis elasticsearch sqlpreview 2>/dev/null || true
        docker rm mysql-8.0 postgres mongodb redis elasticsearch sqlpreview 2>/dev/null || true
        echo "✅ Đã xóa tất cả containers"
    else
        echo "❌ Hủy bỏ thao tác xóa"
    fi
    read -p "Nhấn Enter để tiếp tục..."
}

# Main program loop
main() {
    # Install Docker and setup infrastructure first
    echo "🚀 Khởi tạo môi trường..."
    install_docker
    setup_infrastructure
    
    while true; do
        show_menu
        read -p "Chọn một tùy chọn (0-11): " choice
        echo ""
        
        case $choice in
            1)
                install_docker
                setup_infrastructure
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            2)
                install_mysql
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            3)
                install_postgresql
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            4)
                install_mongodb
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            5)
                install_redis
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            6)
                install_elasticsearch
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            7)
                install_mssql
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            8)
                install_all
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            9)
                check_status
                ;;
            10)
                stop_all
                ;;
            11)
                remove_all
                ;;
            0)
                echo "👋 Tạm biệt!"
                exit 0
                ;;
            *)
                echo "❌ Lựa chọn không hợp lệ. Vui lòng chọn từ 0-11."
                read -p "Nhấn Enter để tiếp tục..."
                ;;
        esac
    done
}

# Run main program
main
