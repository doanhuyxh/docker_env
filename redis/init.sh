# Pull the Redis image from Docker Hub
docker pull redis
# Run a new container with the pulled image
docker run --name some-redis -p 6379:6379 -d redis