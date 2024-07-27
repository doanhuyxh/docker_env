# Pull the MongoDB image from Docker Hub
docker pull mongo

# Run a new container with the pulled image
docker run --name some-mongo -p 27017:27017 -d mongo