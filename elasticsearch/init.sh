# Tạo Docker network nếu chưa tồn tại
NETWORK_NAME="docker-app-network"
docker network create $NETWORK_NAME 2>/dev/null || true

docker pull elasticsearch:7.17.10

docker run --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -d elasticsearch:7.17.10 --network $NETWORK_NAME

