using System.Reflection;
using System.Text.Json;
using Church.BLL.DTOS.AccountDtos;
using Microsoft.Extensions.DependencyInjection;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace Church.Tests;

public sealed class LoginDtoReflectionTests
{
    [Fact]
    public void LoginDTO_can_be_reflected_without_metadata_errors()
    {
        var type = typeof(LoginDTO);

        Assert.Equal("LoginDTO", type.Name);
        Assert.Equal(2, type.GetProperties(BindingFlags.Public | BindingFlags.Instance).Length);

        _ = type.GetCustomAttributes(inherit: true);
        _ = type.GetProperty(nameof(LoginDTO.PhoneNumber))!.GetCustomAttributes(inherit: true);
        _ = type.GetProperty(nameof(LoginDTO.Password))!.GetCustomAttributes(inherit: true);
    }

    [Fact]
    public void LoginDTO_can_be_serialized_for_openapi_contracts()
    {
        var dto = new LoginDTO { PhoneNumber = "01000000000", Password = "secret" };
        var json = JsonSerializer.Serialize(dto);

        Assert.Contains("PhoneNumber", json, StringComparison.Ordinal);
        Assert.Contains("Password", json, StringComparison.Ordinal);
    }

    [Fact]
    public void Swagger_schema_generator_can_describe_LoginDTO()
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddOptions();
        services.AddSwaggerGen();

        using var provider = services.BuildServiceProvider();
        var schemaGenerator = provider.GetRequiredService<ISchemaGenerator>();
        var schemaRepository = new SchemaRepository();

        var schema = schemaGenerator.GenerateSchema(
            typeof(LoginDTO),
            schemaRepository);

        Assert.NotNull(schema);
    }
}
