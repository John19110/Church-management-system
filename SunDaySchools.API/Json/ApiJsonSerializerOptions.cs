using System.Text.Json;
using System.Text.Json.Serialization;

namespace SunDaySchools.API.Json
{
    /// <summary>
    /// Shared JSON settings for API controllers and middleware so Flutter and ASP.NET Core stay aligned.
    /// </summary>
    public static class ApiJsonSerializerOptions
    {
        /// <summary>
        /// Web defaults (camelCase properties) plus string enums matching C# names (e.g. "LongText").
        /// </summary>
        public static JsonSerializerOptions Create()
        {
            var options = new JsonSerializerOptions(JsonSerializerDefaults.Web)
            {
                PropertyNameCaseInsensitive = true
            };

            Configure(options);
            return options;
        }

        public static void Configure(JsonSerializerOptions options)
        {
            options.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
            options.DictionaryKeyPolicy = JsonNamingPolicy.CamelCase;
            options.PropertyNameCaseInsensitive = true;

            // Flutter sends "LongText", "SingleSelect" (PascalCase enum names), not integers.
            if (!options.Converters.Any(c => c is JsonStringEnumConverter))
            {
                options.Converters.Add(new JsonStringEnumConverter(
                    namingPolicy: null,
                    allowIntegerValues: true));
            }
        }
    }
}
