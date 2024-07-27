# Pull the PostgreSQL image from Docker Hub
docker pull postgres

# Run a new container with the pulled image
docker run --name some-postgres -e POSTGRES_PASSWORD=01882904300Huy@ -p 5432:5432 -d postgres