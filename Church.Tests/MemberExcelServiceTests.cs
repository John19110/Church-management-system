using System.Text;
using Church.BLL.Abstractions;
using Church.BLL.DTOS;
using Church.BLL.DTOS.MemberExcel;
using Church.BLL.DTOS.UnifiedForms;
using Church.BLL.Manager.Implementations;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services.UnifiedForms;
using Church.DAL.Abstractions;
using Church.DAL.Models;
using Church.DAL.Models.CustomFields;
using Church.DAL.Repository.Interfaces;
using Church.Domain;
using Moq;

namespace Church.Tests;

public sealed class MemberExcelServiceTests
{
    private readonly Mock<IUnifiedEntityFormManager> _forms = new();
    private readonly Mock<IMemberManager> _members = new();
    private readonly Mock<IMemberRepository> _memberRepo = new();
    private readonly Mock<IMeetingRepository> _meetings = new();
    private readonly Mock<IClassroomRepository> _classrooms = new();
    private readonly Mock<ITenantContext> _tenant = new();
    private readonly Mock<ICurrentUserContext> _user = new();

    public MemberExcelServiceTests()
    {
        Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
        _tenant.SetupGet(t => t.ChurchId).Returns(1);
        _user.Setup(u => u.IsInRole("Admin")).Returns(true);
        _user.Setup(u => u.IsInRole("SuperAdmin")).Returns(false);
        _user.Setup(u => u.IsInRole("Servant")).Returns(false);

        _forms.Setup(f => f.GetFormSchemaAsync(
                CustomFieldEntityNames.Member,
                It.IsAny<EntityFormMode>()))
            .ReturnsAsync(SampleSchema());

        _meetings.Setup(m => m.GetByIdAsync(10))
            .ReturnsAsync(new Meeting
            {
                Id = 10,
                Name = "Meeting A",
                ChurchId = 1,
                HasClassrooms = false
            });

        _members.Setup(m => m.GetAllMembersByMeetingIdAsync(10))
            .ReturnsAsync(Array.Empty<MemberReadDTO>());
        _members.Setup(m => m.GetByMeetingIdAsync(10))
            .ReturnsAsync(Array.Empty<MemberReadDTO>());
        _members.Setup(m => m.GetAssignedByMeetingIdAsync(10))
            .ReturnsAsync(Array.Empty<MemberReadDTO>());
    }

    private MemberExcelService CreateSut() => new(
        _forms.Object,
        _members.Object,
        _memberRepo.Object,
        _meetings.Object,
        _classrooms.Object,
        _tenant.Object,
        _user.Object);

    private static EntityFormSchemaDto SampleSchema() => new()
    {
        EntityName = CustomFieldEntityNames.Member,
        Fields =
        [
            new UnifiedFieldDefinitionDto
            {
                FieldKey = "name1",
                DisplayName = "First Name",
                DisplayNameAr = "الاسم الأول",
                DataType = CustomFieldDataType.Text,
                SortOrder = 10,
                IsBuiltIn = true,
                IsRequired = true
            },
            new UnifiedFieldDefinitionDto
            {
                FieldKey = "name2",
                DisplayName = "Middle Name",
                DisplayNameAr = "الاسم الأوسط",
                DataType = CustomFieldDataType.Text,
                SortOrder = 20,
                IsBuiltIn = true
            },
            new UnifiedFieldDefinitionDto
            {
                FieldKey = "name3",
                DisplayName = "Last Name",
                DisplayNameAr = "الاسم الأخير",
                DataType = CustomFieldDataType.Text,
                SortOrder = 30,
                IsBuiltIn = true
            },
            new UnifiedFieldDefinitionDto
            {
                FieldKey = "address",
                DisplayName = "Address",
                DisplayNameAr = "العنوان",
                DataType = CustomFieldDataType.LongText,
                SortOrder = 40,
                IsBuiltIn = true
            },
            new UnifiedFieldDefinitionDto
            {
                FieldKey = "schoolYear",
                DisplayName = "School Year",
                DataType = CustomFieldDataType.Text,
                SortOrder = 50,
                CustomFieldDefinitionId = 99
            }
        ]
    };

    [Fact]
    public async Task GenerateTemplate_includes_system_and_custom_fields()
    {
        var sut = CreateSut();
        var file = await sut.GenerateTemplateAsync(MemberExcelScope.Meeting, 10, "en");

        Assert.NotEmpty(file.Content);
        Assert.EndsWith(".xlsx", file.FileName);

        var columns = await sut.GetColumnsAsync(MemberExcelScope.Meeting, 10, "en");
        Assert.Contains(columns, c => c.FieldKey == "name1");
        Assert.Contains(columns, c => c.FieldKey == "schoolYear");
        Assert.DoesNotContain(columns, c => c.FieldKey == MemberExcelService.ClassroomFieldKey);
    }

    [Fact]
    public async Task GenerateTemplate_arabic_uses_display_name_ar()
    {
        var sut = CreateSut();
        var columns = await sut.GetColumnsAsync(MemberExcelScope.Meeting, 10, "ar");
        Assert.Equal("الاسم الأول", columns.First(c => c.FieldKey == "name1").Header);
    }

    [Fact]
    public async Task GenerateTemplate_with_classrooms_adds_group_column()
    {
        _meetings.Setup(m => m.GetByIdAsync(11))
            .ReturnsAsync(new Meeting
            {
                Id = 11,
                Name = "Meeting B",
                ChurchId = 1,
                HasClassrooms = true
            });
        _classrooms.Setup(c => c.GetByMeetingIdAsync(11))
            .ReturnsAsync(new List<Classroom>
            {
                new() { Id = 1, Name = "Grade 5", MeetingId = 11, ChurchId = 1 }
            });

        var sut = CreateSut();
        var columns = await sut.GetColumnsAsync(MemberExcelScope.Meeting, 11, "en");
        Assert.Contains(columns, c => c.FieldKey == MemberExcelService.ClassroomFieldKey);
    }

    [Fact]
    public async Task Preview_rejects_outdated_template_when_signature_missing()
    {
        var sut = CreateSut();
        // Minimal fake xlsx without signature: ClosedXML empty workbook saved
        using var wb = new ClosedXML.Excel.XLWorkbook();
        wb.AddWorksheet("Members").Cell(1, 1).Value = "First Name";
        using var ms = new MemoryStream();
        wb.SaveAs(ms);
        ms.Position = 0;

        var preview = await sut.PreviewImportAsync(
            MemberExcelScope.Meeting,
            10,
            ms,
            "old.xlsx",
            "en");

        Assert.False(preview.IsTemplateValid);
        Assert.Contains("outdated", preview.TemplateError!, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Import_name_only_row_creates_member()
    {
        var sut = CreateSut();
        var template = await sut.GenerateTemplateAsync(MemberExcelScope.Meeting, 10, "en");

        using var filled = FillTemplate(template.Content, new Dictionary<string, string>
        {
            ["First Name"] = "John",
            ["Middle Name"] = "A",
            ["Last Name"] = "Polis"
        });

        _members.Setup(m => m.AddAsync(
                It.Is<MemberAddDTO>(d =>
                    d.Name1 == "John" && d.Name2 == "A" && d.Name3 == "Polis"),
                null,
                10))
            .ReturnsAsync(42);

        _forms.Setup(f => f.SaveFormDataAsync(
                CustomFieldEntityNames.Member,
                42,
                It.IsAny<SaveEntityFormDto>()))
            .Returns(Task.CompletedTask);

        var result = await sut.ImportAsync(
            MemberExcelScope.Meeting,
            10,
            filled,
            "members.xlsx",
            MemberExcelDuplicateMode.Skip,
            "en");

        Assert.Equal(1, result.SuccessfullyImported);
        Assert.Equal(0, result.Failed);
    }

    [Fact]
    public async Task Preview_missing_name_is_invalid()
    {
        var sut = CreateSut();
        var template = await sut.GenerateTemplateAsync(MemberExcelScope.Meeting, 10, "en");
        using var filled = FillTemplate(template.Content, new Dictionary<string, string>
        {
            ["First Name"] = "John",
            ["Middle Name"] = "",
            ["Last Name"] = "Polis"
        });

        var preview = await sut.PreviewImportAsync(
            MemberExcelScope.Meeting,
            10,
            filled,
            "members.xlsx",
            "en");

        Assert.True(preview.IsTemplateValid);
        Assert.Single(preview.InvalidRows);
        Assert.Contains("required", preview.InvalidRows[0].Reason, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Preview_detects_duplicate_case_and_whitespace_insensitive()
    {
        _members.Setup(m => m.GetAllMembersByMeetingIdAsync(10))
            .ReturnsAsync(new[]
            {
                new MemberReadDTO
                {
                    Id = 7,
                    Name1 = "John",
                    Name2 = "A",
                    Name3 = "Polis",
                    FullName = "John A Polis"
                }
            });

        var sut = CreateSut();
        var template = await sut.GenerateTemplateAsync(MemberExcelScope.Meeting, 10, "en");
        using var filled = FillTemplate(template.Content, new Dictionary<string, string>
        {
            ["First Name"] = "  john ",
            ["Middle Name"] = "a",
            ["Last Name"] = "POLIS"
        });

        var preview = await sut.PreviewImportAsync(
            MemberExcelScope.Meeting,
            10,
            filled,
            "members.xlsx",
            "en");

        Assert.Single(preview.DuplicateRows);
        Assert.Equal(7, preview.DuplicateRows[0].ExistingMemberId);
    }

    [Fact]
    public async Task Import_skip_duplicate_does_not_update()
    {
        _members.Setup(m => m.GetAllMembersByMeetingIdAsync(10))
            .ReturnsAsync(new[]
            {
                new MemberReadDTO { Id = 7, Name1 = "John", Name2 = "A", Name3 = "Polis" }
            });

        var sut = CreateSut();
        var template = await sut.GenerateTemplateAsync(MemberExcelScope.Meeting, 10, "en");
        using var filled = FillTemplate(template.Content, new Dictionary<string, string>
        {
            ["First Name"] = "John",
            ["Middle Name"] = "A",
            ["Last Name"] = "Polis",
            ["Address"] = "Cairo"
        });

        var result = await sut.ImportAsync(
            MemberExcelScope.Meeting,
            10,
            filled,
            "members.xlsx",
            MemberExcelDuplicateMode.Skip,
            "en");

        Assert.Equal(1, result.DuplicatesSkipped);
        _members.Verify(m => m.UpdateAsync(It.IsAny<MemberUpdateDTO>()), Times.Never);
    }

    [Fact]
    public async Task Import_update_duplicate_calls_update()
    {
        _members.Setup(m => m.GetAllMembersByMeetingIdAsync(10))
            .ReturnsAsync(new[]
            {
                new MemberReadDTO { Id = 7, Name1 = "John", Name2 = "A", Name3 = "Polis" }
            });
        _members.Setup(m => m.UpdateAsync(It.IsAny<MemberUpdateDTO>()))
            .Returns(Task.CompletedTask);
        _forms.Setup(f => f.SaveFormDataAsync(
                CustomFieldEntityNames.Member,
                7,
                It.IsAny<SaveEntityFormDto>()))
            .Returns(Task.CompletedTask);

        var sut = CreateSut();
        var template = await sut.GenerateTemplateAsync(MemberExcelScope.Meeting, 10, "en");
        using var filled = FillTemplate(template.Content, new Dictionary<string, string>
        {
            ["First Name"] = "John",
            ["Middle Name"] = "A",
            ["Last Name"] = "Polis",
            ["Address"] = "Cairo"
        });

        var result = await sut.ImportAsync(
            MemberExcelScope.Meeting,
            10,
            filled,
            "members.xlsx",
            MemberExcelDuplicateMode.Update,
            "en");

        Assert.Equal(1, result.Updated);
        _members.Verify(
            m => m.UpdateAsync(It.Is<MemberUpdateDTO>(u => u.Id == 7 && u.Address == "Cairo")),
            Times.Once);
    }

    [Fact]
    public async Task Preview_invalid_group_is_rejected()
    {
        _meetings.Setup(m => m.GetByIdAsync(11))
            .ReturnsAsync(new Meeting
            {
                Id = 11,
                Name = "Meeting B",
                ChurchId = 1,
                HasClassrooms = true
            });
        _classrooms.Setup(c => c.GetByMeetingIdAsync(11))
            .ReturnsAsync(new List<Classroom>
            {
                new() { Id = 1, Name = "Grade 5", MeetingId = 11, ChurchId = 1 }
            });
        _members.Setup(m => m.GetAllMembersByMeetingIdAsync(11))
            .ReturnsAsync(Array.Empty<MemberReadDTO>());

        var sut = CreateSut();
        var template = await sut.GenerateTemplateAsync(MemberExcelScope.Meeting, 11, "en");
        using var filled = FillTemplate(template.Content, new Dictionary<string, string>
        {
            ["Group/Classroom"] = "Grade 7",
            ["First Name"] = "Peter",
            ["Middle Name"] = "B",
            ["Last Name"] = "Smith"
        });

        var preview = await sut.PreviewImportAsync(
            MemberExcelScope.Meeting,
            11,
            filled,
            "members.xlsx",
            "en");

        Assert.Single(preview.InvalidRows);
        Assert.Contains("Grade 7", preview.InvalidRows[0].Reason);
    }

    [Fact]
    public async Task Church_wide_requires_superadmin()
    {
        var sut = CreateSut();
        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            sut.GenerateTemplateAsync(MemberExcelScope.Church, null, "en"));
    }

    [Fact]
    public async Task Church_wide_template_includes_meeting_column()
    {
        _user.Setup(u => u.IsInRole("SuperAdmin")).Returns(true);
        _user.Setup(u => u.IsInRole("Admin")).Returns(false);
        var sut = CreateSut();
        var columns = await sut.GetColumnsAsync(MemberExcelScope.Church, null, "en");
        Assert.Contains(columns, c => c.FieldKey == MemberExcelService.MeetingFieldKey);
        Assert.Contains(columns, c => c.FieldKey == MemberExcelService.ClassroomFieldKey);
    }

    [Fact]
    public async Task Church_wide_import_rejects_unknown_meeting()
    {
        _user.Setup(u => u.IsInRole("SuperAdmin")).Returns(true);
        _user.Setup(u => u.IsInRole("Admin")).Returns(false);
        _meetings.Setup(m => m.GetByChurchIdAsync(1))
            .ReturnsAsync(new List<Meeting>
            {
                new() { Id = 10, Name = "Meeting A", ChurchId = 1, HasClassrooms = false }
            });
        _members.Setup(m => m.GetAllAsync()).ReturnsAsync(Array.Empty<MemberReadDTO>());

        var sut = CreateSut();
        var template = await sut.GenerateTemplateAsync(MemberExcelScope.Church, null, "en");
        using var filled = FillTemplate(template.Content, new Dictionary<string, string>
        {
            ["Meeting"] = "Primary Meeting",
            ["First Name"] = "Sam",
            ["Middle Name"] = "C",
            ["Last Name"] = "Lee"
        });

        var preview = await sut.PreviewImportAsync(
            MemberExcelScope.Church,
            null,
            filled,
            "members.xlsx",
            "en");

        Assert.Single(preview.InvalidRows);
        Assert.Contains("Primary Meeting", preview.InvalidRows[0].Reason);
    }

    [Fact]
    public async Task Preview_rejects_non_excel_extension()
    {
        var sut = CreateSut();
        using var ms = new MemoryStream(Encoding.UTF8.GetBytes("not excel"));
        var preview = await sut.PreviewImportAsync(
            MemberExcelScope.Meeting,
            10,
            ms,
            "members.csv",
            "en");
        Assert.False(preview.IsTemplateValid);
        Assert.Contains("Excel", preview.TemplateError!, StringComparison.OrdinalIgnoreCase);
    }

    private static MemoryStream FillTemplate(
        byte[] templateBytes,
        IReadOnlyDictionary<string, string> values)
    {
        using var input = new MemoryStream(templateBytes);
        using var workbook = new ClosedXML.Excel.XLWorkbook(input);
        var sheet = workbook.Worksheet(MemberExcelService.DataSheetName);
        var headers = new Dictionary<string, int>(StringComparer.Ordinal);
        var lastCol = sheet.Row(1).LastCellUsed()!.Address.ColumnNumber;
        for (var c = 1; c <= lastCol; c++)
            headers[sheet.Cell(1, c).GetString()] = c;

        foreach (var pair in values)
        {
            if (!headers.TryGetValue(pair.Key, out var col))
                continue;
            sheet.Cell(2, col).Value = pair.Value;
        }

        var output = new MemoryStream();
        workbook.SaveAs(output);
        output.Position = 0;
        return output;
    }
}
