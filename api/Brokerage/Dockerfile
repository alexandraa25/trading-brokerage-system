FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY Brokerage/Brokerage.csproj Brokerage/
RUN dotnet restore Brokerage/Brokerage.csproj

COPY Brokerage/ Brokerage/
RUN dotnet publish Brokerage/Brokerage.csproj --configuration Release --no-restore --output /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

EXPOSE 8080
ENTRYPOINT ["dotnet", "Brokerage.dll"]
