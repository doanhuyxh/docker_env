#!/bin/bash
# Xác định hệ điều hành
OS=$(uname -s)
# Đặt đường dẫn bind mount dựa trên hệ điều hành
case "$OS" in
  Linux*)   # Ubuntu hoặc các hệ điều hành Linux-based
    BIND_MOUNT_PATH="/home/csdl_data/rabbitmq"
    ;;
  Darwin*)  # macOS
    BIND_MOUNT_PATH="/Users/user/Desktop/Code_Data/data_csdl/rabbitmq"
    ;;
  CYGWIN*|MINGW*|MSYS*)  # Windows (dùng Git Bash hoặc tương tự)
    BIND_MOUNT_PATH="/c/data/rabbitmq"
    ;;
  *)
    echo "Hệ điều hành không được hỗ trợ!"
    exit 1
    ;;
esac
# Tạo thư mục bind mount nếu chưa tồn tại
mkdir -p "$BIND_MOUNT_PATH"
# Tạo Docker network nếu chưa tồn tại
NETWORK_NAME="docker-app-network"
docker network create $NETWORK_NAME 2>/dev/null || true
# Pull the RabbitMQ image from Docker Hub
docker pull rabbitmq:management
# Run a new container with the pulled image, sử dụng bind mount
docker run --name rabbitmq \
  --network $NETWORK_NAME \
  -p 5672:5672 \
  -p 15672:15672 \
  -v "$BIND_MOUNT_PATH:/var/lib/rabbitmq" \
  -d rabbitmq:management