#!/bin/bash

# Xác định hệ điều hành
OS=$(uname -s)

# Đặt đường dẫn bind mount dựa trên hệ điều hành
case "$OS" in
  Linux*)   # Ubuntu hoặc các hệ điều hành Linux-based
    BIND_MOUNT_PATH="/var/www/csdl_data/mssql"
    ;;
  Darwin*)  # macOS
    BIND_MOUNT_PATH="/Users/user/Desktop/Code_Data/data_csdl/mssql"
    ;;
  CYGWIN*|MINGW*|MSYS*)  # Windows (dùng Git Bash hoặc tương tự)
    BIND_MOUNT_PATH="/c/data/mssql"
    ;;
  *)
    echo "Hệ điều hành không được hỗ trợ!"
    exit 1
    ;;
esac

# Tạo thư mục bind mount nếu chưa tồn tại
mkdir -p "$BIND_MOUNT_PATH"

# Pull the MS SQL Server image from Docker Hub
docker pull mcr.microsoft.com/mssql/server:2022-latest

# Run a new container with the pulled image, sử dụng bind mount
docker run -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=01882904300Huy@" \
  -e "MSSQL_PID=Evaluation" \
  -p 0.0.0.0:1433:1433 \
  --name sqlpreview \
  -v "$BIND_MOUNT_PATH:/var/opt/mssql" \
  -d mcr.microsoft.com/mssql/server:2022-latest


