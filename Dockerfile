# Build runtime image
FROM microsoft/aspnetcore:2.0
WORKDIR /app
COPY /app .
ENTRYPOINT ["dotnet", "k8api.dll"]
