# Pull the MS SQL Server image from Docker Hub
docker pull mcr.microsoft.com/mssql/server:2022-latest

# Run a new container with the pulled image
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=01882904300Huy@' -p 1433:1433 --name sql_server -d mcr.microsoft.com/mssql/server:2022-latest