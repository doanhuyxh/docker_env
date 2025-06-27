# Tạo Docker network nếu chưa tồn tại
NETWORK_NAME="docker-app-network"
docker network create $NETWORK_NAME 2>/dev/null || true

# Pull the Redis image from Docker Hub
docker pull redis
# Run a new container with the pulled image
docker run --name redis -p 6379:6379 -d redis --network $NETWORK