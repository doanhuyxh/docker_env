#!/bin/bash

# Dừng và xóa tất cả container
echo "Đang dừng và xóa tất cả container..."
docker ps -a -q | xargs -r docker stop
    docker ps -a -q | xargs -r docker rm

# Xóa tất cả image
echo "Đang xóa tất cả image..."
docker images -q | sort -u | xargs -r docker rmi -f

# Xóa tất cả volume
echo "Đang xóa tất cả volume..."
docker volume ls -q | xargs -r docker volume rm

echo "Đã xóa hết container, image và volume."