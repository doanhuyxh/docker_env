# Pull the MS SQL Server image from Docker Hub
docker pull mcr.microsoft.com/mssql/server:2022-latest

# Run a new container with the pulled image
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=01882904300Huy@" -e "MSSQL_PID=Evaluation" -p 1433:1433 --name sqlpreview -d mcr.microsoft.com/mssql/server:2022-latest