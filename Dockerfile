FROM microsoft/aspnetcore-build:2.0
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

# Build runtime image
FROM microsoft/aspnetcore:2.0
WORKDIR /app
COPY --from=0 /app/out .
ENTRYPOINT ["dotnet", "k8sapi.dll"]
