# Pull the MySQL 8.0 image from Docker Hub
docker pull mysql:8.0

# Run a new container with the pulled image
docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=01882904300Huy@ -e MYSQL_ROOT_HOST=% -p 3306:3306 -d mysql:8.0
# The above command starts a new container and provides the root password. 
# Replace 'my-secret-pw' with your desired root password.