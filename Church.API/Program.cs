using Church.API.Infrastructure.DependencyInjection;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddApiServices()
    .AddApplicationServices(builder.Configuration)
    .AddDatabaseServices(builder.Configuration)
    .AddIdentityServices()
    .AddAuthenticationServices(builder.Configuration)
    .AddAuthorizationServices()
    .AddCorsServices(builder.Configuration, builder.Environment)
    .AddRateLimitingServices()
    .AddSwaggerServices();

var app = builder.Build();

await app.InitializeDatabaseAsync();
await app.SeedIdentityAsync();

app.UseApplicationMiddleware();
app.MapApplicationEndpoints();

app.Run();
