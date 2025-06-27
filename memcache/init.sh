# Tạo Docker network nếu chưa tồn tại
NETWORK_NAME="docker-app-network"
docker network create $NETWORK_NAME 2>/dev/null || true

docker pull memcached

docker run --name memcache p 11211:11211 -d memcached --network $NETWORK_NAME

