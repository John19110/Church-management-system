using System;
using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace SunDaySchools.API.Json
{
    public sealed class TimeOnlyJsonConverter : JsonConverter<TimeOnly>
    {
        private const string Format = "HH:mm:ss";

        public override TimeOnly Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType != JsonTokenType.String)
                throw new JsonException("Expected time string.");

            var value = reader.GetString();
            if (string.IsNullOrWhiteSpace(value))
                throw new JsonException("Time value is required.");

            if (TimeOnly.TryParseExact(value, Format, CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed))
                return parsed;

            if (TimeOnly.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out parsed))
                return parsed;

            throw new JsonException($"Invalid time format. Expected '{Format}'.");
        }

        public override void Write(Utf8JsonWriter writer, TimeOnly value, JsonSerializerOptions options)
        {
            writer.WriteStringValue(value.ToString(Format, CultureInfo.InvariantCulture));
        }
    }
}

