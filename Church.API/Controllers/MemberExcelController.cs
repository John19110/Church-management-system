using Church.BLL.DTOS.MemberExcel;
using Church.BLL.Manager.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Church.API.Controllers
{
    [ApiController]
    [Authorize(Roles = "Servant,Admin,SuperAdmin")]
    public class MemberExcelController : ControllerBase
    {
        private readonly IMemberExcelService _excelService;

        public MemberExcelController(IMemberExcelService excelService)
        {
            _excelService = excelService;
        }

        [HttpGet("/api/meetings/{meetingId:int}/members/excel/columns")]
        public async Task<ActionResult<IReadOnlyList<MemberExcelExportFieldDto>>> GetMeetingColumns(
            int meetingId,
            [FromQuery] string culture = "en")
        {
            var fields = await _excelService.GetExportFieldsAsync(
                MemberExcelScope.Meeting,
                meetingId,
                culture);
            return Ok(fields);
        }

        [HttpGet("/api/meetings/{meetingId:int}/members/excel/template")]
        public async Task<IActionResult> DownloadMeetingTemplate(
            int meetingId,
            [FromQuery] string culture = "en")
        {
            var file = await _excelService.GenerateTemplateAsync(
                MemberExcelScope.Meeting,
                meetingId,
                culture);
            return File(file.Content, file.ContentType, file.FileName);
        }

        [HttpPost("/api/meetings/{meetingId:int}/members/excel/preview")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<MemberExcelPreviewDto>> PreviewMeetingImport(
            int meetingId,
            IFormFile file,
            [FromQuery] string culture = "en")
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "Excel file is required." });

            await using var stream = file.OpenReadStream();
            var preview = await _excelService.PreviewImportAsync(
                MemberExcelScope.Meeting,
                meetingId,
                stream,
                file.FileName,
                culture);
            return Ok(preview);
        }

        [HttpPost("/api/meetings/{meetingId:int}/members/excel/import")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<MemberExcelImportResultDto>> ImportMeetingMembers(
            int meetingId,
            IFormFile file,
            [FromQuery] MemberExcelDuplicateMode duplicateMode = MemberExcelDuplicateMode.Skip,
            [FromQuery] string culture = "en")
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "Excel file is required." });

            await using var stream = file.OpenReadStream();
            var result = await _excelService.ImportAsync(
                MemberExcelScope.Meeting,
                meetingId,
                stream,
                file.FileName,
                duplicateMode,
                culture);
            return Ok(result);
        }

        [HttpGet("/api/meetings/{meetingId:int}/members/excel/export")]
        public async Task<IActionResult> ExportMeetingMembers(
            int meetingId,
            [FromQuery] string? fields = null,
            [FromQuery] string culture = "en")
        {
            var selected = ParseFields(fields);
            var file = await _excelService.ExportAsync(
                MemberExcelScope.Meeting,
                meetingId,
                selected,
                culture);
            return File(file.Content, file.ContentType, file.FileName);
        }

        [HttpGet("/api/church/members/excel/columns")]
        [Authorize(Roles = "SuperAdmin")]
        public async Task<ActionResult<IReadOnlyList<MemberExcelExportFieldDto>>> GetChurchColumns(
            [FromQuery] string culture = "en")
        {
            var fields = await _excelService.GetExportFieldsAsync(
                MemberExcelScope.Church,
                null,
                culture);
            return Ok(fields);
        }

        [HttpGet("/api/church/members/excel/template")]
        [Authorize(Roles = "SuperAdmin")]
        public async Task<IActionResult> DownloadChurchTemplate([FromQuery] string culture = "en")
        {
            var file = await _excelService.GenerateTemplateAsync(
                MemberExcelScope.Church,
                null,
                culture);
            return File(file.Content, file.ContentType, file.FileName);
        }

        [HttpPost("/api/church/members/excel/preview")]
        [Authorize(Roles = "SuperAdmin")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<MemberExcelPreviewDto>> PreviewChurchImport(
            IFormFile file,
            [FromQuery] string culture = "en")
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "Excel file is required." });

            await using var stream = file.OpenReadStream();
            var preview = await _excelService.PreviewImportAsync(
                MemberExcelScope.Church,
                null,
                stream,
                file.FileName,
                culture);
            return Ok(preview);
        }

        [HttpPost("/api/church/members/excel/import")]
        [Authorize(Roles = "SuperAdmin")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<MemberExcelImportResultDto>> ImportChurchMembers(
            IFormFile file,
            [FromQuery] MemberExcelDuplicateMode duplicateMode = MemberExcelDuplicateMode.Skip,
            [FromQuery] string culture = "en")
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "Excel file is required." });

            await using var stream = file.OpenReadStream();
            var result = await _excelService.ImportAsync(
                MemberExcelScope.Church,
                null,
                stream,
                file.FileName,
                duplicateMode,
                culture);
            return Ok(result);
        }

        [HttpGet("/api/church/members/excel/export")]
        [Authorize(Roles = "SuperAdmin")]
        public async Task<IActionResult> ExportChurchMembers(
            [FromQuery] string? fields = null,
            [FromQuery] string culture = "en")
        {
            var selected = ParseFields(fields);
            var file = await _excelService.ExportAsync(
                MemberExcelScope.Church,
                null,
                selected,
                culture);
            return File(file.Content, file.ContentType, file.FileName);
        }

        private static IReadOnlyList<string> ParseFields(string? fields)
        {
            if (string.IsNullOrWhiteSpace(fields))
                return Array.Empty<string>();

            return fields
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .ToList();
        }
    }
}
