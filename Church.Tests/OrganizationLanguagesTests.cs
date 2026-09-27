using Church.BLL.Services;

namespace Church.Tests;

public sealed class OrganizationLanguagesTests
{
    [Theory]
    [InlineData(null, "en,ar")]
    [InlineData("", "en,ar")]
    [InlineData("en", "en")]
    [InlineData("ar", "ar")]
    [InlineData("en,ar", "en,ar")]
    [InlineData("arabic,english", "ar,en")]
    public void Parse_and_serialize_supported_languages(string? raw, string expected)
    {
        var parsed = OrganizationLanguages.ParseSupported(raw);
        Assert.Equal(expected, OrganizationLanguages.Serialize(parsed));
    }

    [Fact]
    public void Default_must_be_one_of_the_supported_languages()
    {
        var supported = OrganizationLanguages.ParseSupported("ar");
        Assert.Equal("ar", OrganizationLanguages.NormalizeDefault("en", supported));
        Assert.Equal("ar", OrganizationLanguages.NormalizeDefault("ar", supported));
    }

    [Fact]
    public void Preferred_language_must_be_supported()
    {
        var supported = OrganizationLanguages.ParseSupported("en");
        Assert.Equal("en", OrganizationLanguages.NormalizePreferred("en", supported));
        Assert.Null(OrganizationLanguages.NormalizePreferred("ar", supported));
        Assert.Null(OrganizationLanguages.NormalizePreferred(null, supported));
    }
}
