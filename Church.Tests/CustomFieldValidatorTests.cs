using Church.BLL.Services.CustomFields;
using Church.DAL.Models.CustomFields;

namespace Church.Tests;

public sealed class CustomFieldValidatorTests
{
    private readonly CustomFieldValidator _validator = new();

    private static CustomFieldDefinition Def(
        CustomFieldDataType type,
        bool required = false,
        string? regex = null,
        params (string Value, string Text)[] options)
    {
        var def = new CustomFieldDefinition
        {
            DisplayName = "Sample",
            DataType = type,
            IsRequired = required,
            ValidationRegex = regex
        };
        foreach (var (value, text) in options)
            def.Options.Add(new CustomFieldOption { Value = value, DisplayText = text });
        return def;
    }

    [Theory]
    [InlineData(CustomFieldDataType.Number, "42", true)]
    [InlineData(CustomFieldDataType.Number, "12.5", false)]
    [InlineData(CustomFieldDataType.Decimal, "12.5", true)]
    [InlineData(CustomFieldDataType.Boolean, "true", true)]
    [InlineData(CustomFieldDataType.Boolean, "1", true)]
    [InlineData(CustomFieldDataType.Boolean, "yes", false)]
    [InlineData(CustomFieldDataType.Date, "2015-06-15", true)]
    [InlineData(CustomFieldDataType.Date, "not-a-date", false)]
    [InlineData(CustomFieldDataType.Json, "{\"a\":1}", true)]
    [InlineData(CustomFieldDataType.Json, "not-json", false)]
    public void TryValidateValue_type_rules(CustomFieldDataType type, string value, bool expectedOk)
    {
        var ok = _validator.TryValidateValue(Def(type), value, out var normalized, out var error);
        Assert.Equal(expectedOk, ok);
        if (expectedOk)
            Assert.False(string.IsNullOrWhiteSpace(normalized));
        else
            Assert.False(string.IsNullOrWhiteSpace(error));
    }

    [Fact]
    public void Required_empty_fails()
    {
        var ok = _validator.TryValidateValue(Def(CustomFieldDataType.Text, required: true), "  ", out _, out var error);
        Assert.False(ok);
        Assert.Contains("required", error, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Optional_empty_becomes_null()
    {
        var ok = _validator.TryValidateValue(Def(CustomFieldDataType.Text), "", out var normalized, out _);
        Assert.True(ok);
        Assert.Null(normalized);
    }

    [Fact]
    public void Regex_mismatch_fails()
    {
        var ok = _validator.TryValidateValue(
            Def(CustomFieldDataType.Text, regex: "^[A-Z]{3}$"),
            "abc",
            out _,
            out var error);
        Assert.False(ok);
        Assert.Contains("invalid format", error, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Boolean_normalizes_zero_one()
    {
        Assert.True(_validator.TryValidateValue(Def(CustomFieldDataType.Boolean), "1", out var t, out _));
        Assert.Equal("true", t);
        Assert.True(_validator.TryValidateValue(Def(CustomFieldDataType.Boolean), "0", out var f, out _));
        Assert.Equal("false", f);
    }

    [Fact]
    public void SingleSelect_rejects_unknown_option()
    {
        var def = Def(CustomFieldDataType.SingleSelect, options: [("A", "Alpha"), ("B", "Beta")]);
        Assert.True(_validator.TryValidateValue(def, "A", out _, out _));
        Assert.False(_validator.TryValidateValue(def, "Z", out _, out _));
    }

    [Fact]
    public void MultiSelect_normalizes_csv_to_json()
    {
        var def = Def(CustomFieldDataType.MultiSelect, options: [("A", "Alpha"), ("B", "Beta")]);
        Assert.True(_validator.TryValidateValue(def, "A,B", out var normalized, out _));
        Assert.Equal("[\"A\",\"B\"]", normalized);
    }

    [Fact]
    public void Arabic_unicode_text_accepted()
    {
        var value = "ملاحظة الاختبار 🙏";
        Assert.True(_validator.TryValidateValue(Def(CustomFieldDataType.Text), value, out var normalized, out _));
        Assert.Equal(value, normalized);
    }
}
