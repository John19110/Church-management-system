using Church.BLL.DTOS.MemberExcel;

namespace Church.BLL.Manager.Interfaces
{
    public interface IMemberExcelService
    {
        Task<IReadOnlyList<MemberExcelColumnDto>> GetColumnsAsync(
            MemberExcelScope scope,
            int? meetingId,
            string culture);

        Task<IReadOnlyList<MemberExcelExportFieldDto>> GetExportFieldsAsync(
            MemberExcelScope scope,
            int? meetingId,
            string culture);

        Task<MemberExcelFileResult> GenerateTemplateAsync(
            MemberExcelScope scope,
            int? meetingId,
            string culture);

        Task<MemberExcelPreviewDto> PreviewImportAsync(
            MemberExcelScope scope,
            int? meetingId,
            Stream fileStream,
            string fileName,
            string culture);

        Task<MemberExcelImportResultDto> ImportAsync(
            MemberExcelScope scope,
            int? meetingId,
            Stream fileStream,
            string fileName,
            MemberExcelDuplicateMode duplicateMode,
            string culture);

        Task<MemberExcelFileResult> ExportAsync(
            MemberExcelScope scope,
            int? meetingId,
            IReadOnlyList<string> selectedFieldKeys,
            string culture);
    }
}
