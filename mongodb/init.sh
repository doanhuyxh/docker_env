# Pull the MongoDB image from Docker Hub
docker pull mongo

# Run a new container with the pulled image
docker run -d --name mongo_database \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=01882904300Huy@ \
  -p 27017:27017 \
  mongo
