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
            switch (reader.TokenType)
            {
                case JsonTokenType.Null:
                    return null;
                case JsonTokenType.String:
                    return reader.GetString();
                case JsonTokenType.Number:
                    if (reader.TryGetInt64(out var l))
                        return l.ToString(CultureInfo.InvariantCulture);
                    if (reader.TryGetDecimal(out var d))
                        return d.ToString(CultureInfo.InvariantCulture);
                    return reader.GetDouble().ToString(CultureInfo.InvariantCulture);
                case JsonTokenType.True:
                    return "true";
                case JsonTokenType.False:
                    return "false";
                case JsonTokenType.StartObject:
                case JsonTokenType.StartArray:
                    using (var doc = JsonDocument.ParseValue(ref reader))
                    {
                        return doc.RootElement.GetRawText();
                    }
                default:
                    throw new JsonException(
                        $"Unsupported JSON token '{reader.TokenType}' for form field value.");
            }
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
