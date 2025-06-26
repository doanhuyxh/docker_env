#!/bin/bash

# Xác định hệ điều hành
OS=$(uname -s)

# Đặt đường dẫn mount dựa trên hệ điều hành
case "$OS" in
  Linux*)   # Ubuntu hoặc các hệ điều hành Linux-based
    MOUNT_PATH="/var/www/csdl_data/mongo"
    ;;
  Darwin*)  # macOS
    MOUNT_PATH="/Users/user/Desktop/Code_Data/data_csdl/mongodb"
    ;;
  CYGWIN*|MINGW*|MSYS*)  # Windows (dùng Git Bash hoặc tương tự)
    MOUNT_PATH="/c/data/mongo"
    ;;
  *)
    echo "Hệ điều hành không được hỗ trợ!"
    exit 1
    ;;
esac

# Tạo thư mục mount nếu chưa tồn tại
mkdir -p "$MOUNT_PATH"

# Pull the MongoDB image from Docker Hub
docker pull mongo

# Run a new container with the pulled image
docker run -d --name mongo_database \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=01882904300Huy@ \
  -p 0.0.0.0:27017:27017 \
  -v "$MOUNT_PATH:/data/db" \
  mongo