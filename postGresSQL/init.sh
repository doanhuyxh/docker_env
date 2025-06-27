#!/bin/bash

# Xác định hệ điều hành
OS=$(uname -s)

# Đặt đường dẫn bind mount dựa trên hệ điều hành
case "$OS" in
  Linux*)   # Ubuntu hoặc các hệ điều hành Linux-based
    BIND_MOUNT_PATH="/home/csdl_data/postgres"
    ;;
  Darwin*)  # macOS
    BIND_MOUNT_PATH="/Users/user/Desktop/Code_Data/data_csdl/postgres"
    ;;
  CYGWIN*|MINGW*|MSYS*)  # Windows (dùng Git Bash hoặc tương tự)
    BIND_MOUNT_PATH="/c/data/postgres"
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

# Pull the PostgreSQL image from Docker Hub
docker pull postgres

# Run a new container with the pulled image, sử dụng bind mount
docker run --name postgres \
  --network $NETWORK_NAME \
  -e POSTGRES_PASSWORD=01882904300Huy@ \
  -p 5432:5432 \
  -v "$BIND_MOUNT_PATH:/var/lib/postgresql/data" \
  -d postgres