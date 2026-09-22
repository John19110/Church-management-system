namespace Church.BLL.DTOS.MemberExcel
{
    public enum MemberExcelScope
    {
        Meeting = 0,
        Church = 1
    }

    public enum MemberExcelDuplicateMode
    {
        Skip = 0,
        Update = 1
    }

    public sealed class MemberExcelColumnDto
    {
        public string FieldKey { get; set; } = string.Empty;
        public string Header { get; set; } = string.Empty;
        public bool IsRequired { get; set; }
        public bool IsStructural { get; set; }
        public string? DataType { get; set; }
    }

    public sealed class MemberExcelFileResult
    {
        public byte[] Content { get; set; } = Array.Empty<byte>();
        public string FileName { get; set; } = "members.xlsx";
        public string ContentType { get; set; } =
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    }

    public sealed class MemberExcelRowIssueDto
    {
        public int RowNumber { get; set; }
        public string? MemberName { get; set; }
        public string Reason { get; set; } = string.Empty;
        public int? ExistingMemberId { get; set; }
    }

    public sealed class MemberExcelPreviewDto
    {
        public bool IsTemplateValid { get; set; }
        public string? TemplateError { get; set; }
        public List<string> InvalidColumns { get; set; } = new();
        public List<string> MissingRequiredColumns { get; set; } = new();
        public int TotalRows { get; set; }
        public List<MemberExcelRowIssueDto> ValidRows { get; set; } = new();
        public List<MemberExcelRowIssueDto> DuplicateRows { get; set; } = new();
        public List<MemberExcelRowIssueDto> InvalidRows { get; set; } = new();
    }

    public sealed class MemberExcelImportResultDto
    {
        public int TotalRows { get; set; }
        public int SuccessfullyImported { get; set; }
        public int Updated { get; set; }
        public int DuplicatesSkipped { get; set; }
        public int Failed { get; set; }
        public List<MemberExcelRowIssueDto> Failures { get; set; } = new();
    }

    public sealed class MemberExcelExportFieldDto
    {
        public string FieldKey { get; set; } = string.Empty;
        public string Header { get; set; } = string.Empty;
        public bool SelectedByDefault { get; set; } = true;
    }
}
