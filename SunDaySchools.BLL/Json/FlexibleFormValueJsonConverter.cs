using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace SunDaySchools.BLL.Json
{
    /// <summary>
    /// Accepts string, number, bool, or JSON object/array for unified form field values.
    /// </summary>
    public sealed class FlexibleFormValueJsonConverter : JsonConverter<string?>
    {
        public override string? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            return reader.TokenType switch
            {
                JsonTokenType.Null => null,
                JsonTokenType.String => reader.GetString(),
                JsonTokenType.Number when reader.TryGetInt64(out var l) =>
                    l.ToString(CultureInfo.InvariantCulture),
                JsonTokenType.Number when reader.TryGetDecimal(out var d) =>
                    d.ToString(CultureInfo.InvariantCulture),
                JsonTokenType.True => "true",
                JsonTokenType.False => "false",
                JsonTokenType.StartObject or JsonTokenType.StartArray =>
                {
                    using var doc = JsonDocument.ParseValue(ref reader);
                    return doc.RootElement.GetRawText();
                },
                _ => throw new JsonException(
                    $"Unsupported JSON token '{reader.TokenType}' for form field value.")
            };
        }

        public override void Write(Utf8JsonWriter writer, string? value, JsonSerializerOptions options)
        {
            if (value == null)
                writer.WriteNullValue();
            else
                writer.WriteStringValue(value);
        }
    }
}
