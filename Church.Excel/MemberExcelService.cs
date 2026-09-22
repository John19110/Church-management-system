using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using ClosedXML.Excel;
using Church.BLL.Abstractions;
using Church.BLL.DTOS;
using Church.BLL.DTOS.MemberExcel;
using Church.BLL.DTOS.UnifiedForms;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services.UnifiedForms;
using Church.DAL.Abstractions;
using Church.DAL.Models;
using Church.DAL.Models.CustomFields;
using Church.DAL.Repository.Interfaces;
using Church.Domain;
using ExcelDataReader;

namespace Church.BLL.Manager.Implementations
{
    public sealed class MemberExcelService : IMemberExcelService
    {
        public const string SignatureProperty = "MyChurch.MemberTemplateSignature";
        public const string MetaSheetName = "_meta";
        public const string MeetingFieldKey = "__meeting";
        public const string ClassroomFieldKey = "__classroom";
        public const string DataSheetName = "Members";

        private static readonly HashSet<string> ExcludedFieldKeys = new(StringComparer.OrdinalIgnoreCase)
        {
            "imageUrl",
            "lastAttendanceDate",
            "totalNumberOfDaysAttended",
            "classroomId"
        };

        private static readonly HashSet<string> RequiredNameKeys = new(StringComparer.OrdinalIgnoreCase)
        {
            "name1",
            "name2",
            "name3"
        };

        private readonly IUnifiedEntityFormManager _formManager;
        private readonly IMemberManager _memberManager;
        private readonly IMemberRepository _memberRepository;
        private readonly IMeetingRepository _meetingRepository;
        private readonly IClassroomRepository _classroomRepository;
        private readonly ITenantContext _tenantContext;
        private readonly ICurrentUserContext _currentUser;

        public MemberExcelService(
            IUnifiedEntityFormManager formManager,
            IMemberManager memberManager,
            IMemberRepository memberRepository,
            IMeetingRepository meetingRepository,
            IClassroomRepository classroomRepository,
            ITenantContext tenantContext,
            ICurrentUserContext currentUser)
        {
            _formManager = formManager;
            _memberManager = memberManager;
            _memberRepository = memberRepository;
            _meetingRepository = meetingRepository;
            _classroomRepository = classroomRepository;
            _tenantContext = tenantContext;
            _currentUser = currentUser;
        }

        public async Task<IReadOnlyList<MemberExcelColumnDto>> GetColumnsAsync(
            MemberExcelScope scope,
            int? meetingId,
            string culture)
        {
            var columns = await BuildColumnsAsync(scope, meetingId, culture);
            return columns;
        }

        public async Task<IReadOnlyList<MemberExcelExportFieldDto>> GetExportFieldsAsync(
            MemberExcelScope scope,
            int? meetingId,
            string culture)
        {
            var columns = await BuildColumnsAsync(scope, meetingId, culture);
            return columns
                .Select(c => new MemberExcelExportFieldDto
                {
                    FieldKey = c.FieldKey,
                    Header = c.Header,
                    SelectedByDefault = true
                })
                .ToList();
        }

        public async Task<MemberExcelFileResult> GenerateTemplateAsync(
            MemberExcelScope scope,
            int? meetingId,
            string culture)
        {
            EnsureScopeAccess(scope, meetingId);
            var columns = await BuildColumnsAsync(scope, meetingId, culture);
            var signature = await BuildSignatureAsync(scope, meetingId, columns);
            var bytes = WriteWorkbook(columns, signature, rows: null);
            var prefix = scope == MemberExcelScope.Church ? "church" : $"meeting-{meetingId}";
            return new MemberExcelFileResult
            {
                Content = bytes,
                FileName = $"members-template-{prefix}.xlsx"
            };
        }

        public async Task<MemberExcelPreviewDto> PreviewImportAsync(
            MemberExcelScope scope,
            int? meetingId,
            Stream fileStream,
            string fileName,
            string culture)
        {
            EnsureScopeAccess(scope, meetingId);
            return await AnalyzeAsync(scope, meetingId, fileStream, fileName, culture, commit: false, default);
        }

        public async Task<MemberExcelImportResultDto> ImportAsync(
            MemberExcelScope scope,
            int? meetingId,
            Stream fileStream,
            string fileName,
            MemberExcelDuplicateMode duplicateMode,
            string culture)
        {
            EnsureScopeAccess(scope, meetingId);
            var preview = await AnalyzeAsync(
                scope,
                meetingId,
                fileStream,
                fileName,
                culture,
                commit: true,
                duplicateMode);

            return new MemberExcelImportResultDto
            {
                TotalRows = preview.TotalRows,
                SuccessfullyImported = preview.ValidRows.Count(r =>
                    string.Equals(r.Reason, "imported", StringComparison.OrdinalIgnoreCase)),
                Updated = preview.ValidRows.Count(r =>
                    string.Equals(r.Reason, "updated", StringComparison.OrdinalIgnoreCase)),
                DuplicatesSkipped = preview.DuplicateRows.Count(r =>
                    string.Equals(r.Reason, "skipped", StringComparison.OrdinalIgnoreCase)),
                Failed = preview.InvalidRows.Count + preview.DuplicateRows.Count(r =>
                    string.Equals(r.Reason, "failed", StringComparison.OrdinalIgnoreCase)),
                Failures = preview.InvalidRows
                    .Concat(preview.DuplicateRows.Where(r =>
                        string.Equals(r.Reason, "failed", StringComparison.OrdinalIgnoreCase)))
                    .ToList()
            };
        }

        public async Task<MemberExcelFileResult> ExportAsync(
            MemberExcelScope scope,
            int? meetingId,
            IReadOnlyList<string> selectedFieldKeys,
            string culture)
        {
            EnsureScopeAccess(scope, meetingId);
            var allColumns = await BuildColumnsAsync(scope, meetingId, culture);
            var selected = selectedFieldKeys is { Count: > 0 }
                ? allColumns
                    .Where(c => selectedFieldKeys.Contains(c.FieldKey, StringComparer.OrdinalIgnoreCase))
                    .ToList()
                : allColumns;

            if (selected.Count == 0)
                selected = allColumns.ToList();

            var signature = await BuildSignatureAsync(scope, meetingId, allColumns);
            var members = await LoadMembersForExportAsync(scope, meetingId);
            var meetingsById = new Dictionary<int, Meeting>();

            if (scope == MemberExcelScope.Church)
            {
                var churchId = _tenantContext.ChurchId
                    ?? throw new UnauthorizedAccessException("ChurchId claim is missing.");
                foreach (var m in await _meetingRepository.GetByChurchIdAsync(churchId))
                    meetingsById[m.Id] = m;
            }
            else if (meetingId is int mid)
            {
                var meeting = await _meetingRepository.GetByIdAsync(mid)
                    ?? throw new NotFoundException($"Meeting with id {mid} was not found.");
                meetingsById[meeting.Id] = meeting;
            }

            var rows = new List<IReadOnlyDictionary<string, string?>>();
            foreach (var member in members)
            {
                var form = await _formManager.GetFormDataAsync(CustomFieldEntityNames.Member, member.Id);
                var map = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase);
                foreach (var field in form.Fields)
                    map[field.FieldKey] = FormatExportValue(field);

                if (selected.Any(c => c.FieldKey == MeetingFieldKey))
                {
                    var entity = await _memberRepository.GetByIdAsync(member.Id);
                    if (entity?.MeetingId is int memberMeetingId
                        && meetingsById.TryGetValue(memberMeetingId, out var meeting))
                    {
                        map[MeetingFieldKey] = meeting.Name;
                    }
                }

                if (selected.Any(c => c.FieldKey == ClassroomFieldKey))
                    map[ClassroomFieldKey] = member.ClassroomName;

                rows.Add(map);
            }

            var bytes = WriteWorkbook(selected, signature, rows);
            var prefix = scope == MemberExcelScope.Church ? "church" : $"meeting-{meetingId}";
            return new MemberExcelFileResult
            {
                Content = bytes,
                FileName = $"members-export-{prefix}.xlsx"
            };
        }

        private void EnsureScopeAccess(MemberExcelScope scope, int? meetingId)
        {
            if (scope == MemberExcelScope.Church)
            {
                if (!_currentUser.IsInRole("SuperAdmin"))
                    throw new UnauthorizedAccessException("Church-wide Excel is SuperAdmin only.");
                if (_tenantContext.ChurchId is null or <= 0)
                    throw new UnauthorizedAccessException("ChurchId claim is missing.");
                return;
            }

            if (meetingId is null or <= 0)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["meetingId"] = new[] { "Meeting id is required." }
                });

            if (!(_currentUser.IsInRole("Admin")
                  || _currentUser.IsInRole("SuperAdmin")
                  || _currentUser.IsInRole("Servant")))
            {
                throw new UnauthorizedAccessException("Not allowed to use Member Excel.");
            }
        }

        private async Task<List<MemberExcelColumnDto>> BuildColumnsAsync(
            MemberExcelScope scope,
            int? meetingId,
            string culture)
        {
            var schema = await _formManager.GetFormSchemaAsync(
                CustomFieldEntityNames.Member,
                EntityFormMode.Create);

            var arabic = IsArabic(culture);
            var columns = new List<MemberExcelColumnDto>();

            if (scope == MemberExcelScope.Church)
            {
                columns.Add(new MemberExcelColumnDto
                {
                    FieldKey = MeetingFieldKey,
                    Header = arabic ? "الاجتماع" : "Meeting",
                    IsRequired = true,
                    IsStructural = true
                });
            }

            bool includeClassroomColumn;
            if (scope == MemberExcelScope.Meeting)
            {
                var meeting = await _meetingRepository.GetByIdAsync(meetingId!.Value)
                    ?? throw new NotFoundException($"Meeting with id {meetingId} was not found.");
                includeClassroomColumn = meeting.HasClassrooms;
            }
            else
            {
                // Church-wide template always includes Group/Classroom; row rules enforce when needed.
                includeClassroomColumn = true;
            }

            if (includeClassroomColumn)
            {
                columns.Add(new MemberExcelColumnDto
                {
                    FieldKey = ClassroomFieldKey,
                    Header = arabic ? "المجموعة" : "Group/Classroom",
                    IsRequired = scope == MemberExcelScope.Meeting,
                    IsStructural = true
                });
            }

            foreach (var field in schema.Fields
                         .Where(f => !f.IsHidden && !f.IsReadOnly)
                         .Where(f => !ExcludedFieldKeys.Contains(f.FieldKey))
                         .OrderBy(f => f.SortOrder)
                         .ThenBy(f => f.FieldKey, StringComparer.OrdinalIgnoreCase))
            {
                var required = RequiredNameKeys.Contains(field.FieldKey);
                columns.Add(new MemberExcelColumnDto
                {
                    FieldKey = field.FieldKey,
                    Header = PickHeader(field, arabic),
                    IsRequired = required,
                    IsStructural = false,
                    DataType = field.DataType.ToString()
                });
            }

            return columns;
        }

        private static string PickHeader(UnifiedFieldDefinitionDto field, bool arabic)
        {
            if (arabic && !string.IsNullOrWhiteSpace(field.DisplayNameAr))
                return field.DisplayNameAr!.Trim();
            return string.IsNullOrWhiteSpace(field.DisplayName)
                ? field.FieldKey
                : field.DisplayName.Trim();
        }

        private static bool IsArabic(string? culture) =>
            !string.IsNullOrWhiteSpace(culture)
            && culture.StartsWith("ar", StringComparison.OrdinalIgnoreCase);

        private async Task<string> BuildSignatureAsync(
            MemberExcelScope scope,
            int? meetingId,
            IReadOnlyList<MemberExcelColumnDto> columns)
        {
            var hasClassrooms = false;
            if (scope == MemberExcelScope.Meeting && meetingId is int mid)
            {
                var meeting = await _meetingRepository.GetByIdAsync(mid);
                hasClassrooms = meeting?.HasClassrooms == true;
            }

            var payload = string.Join(
                "|",
                new[]
                {
                    scope.ToString(),
                    hasClassrooms ? "classrooms" : "no-classrooms",
                    string.Join(",", columns.Select(c => c.FieldKey))
                });

            var hash = SHA256.HashData(Encoding.UTF8.GetBytes(payload));
            return Convert.ToHexString(hash);
        }

        private static byte[] WriteWorkbook(
            IReadOnlyList<MemberExcelColumnDto> columns,
            string signature,
            IReadOnlyList<IReadOnlyDictionary<string, string?>>? rows)
        {
            using var workbook = new XLWorkbook();
            var sheet = workbook.Worksheets.Add(DataSheetName);

            for (var i = 0; i < columns.Count; i++)
            {
                var cell = sheet.Cell(1, i + 1);
                cell.Value = columns[i].Header;
                cell.Style.Font.Bold = true;
                cell.Style.Fill.BackgroundColor = XLColor.LightSteelBlue;
            }

            if (rows != null)
            {
                for (var r = 0; r < rows.Count; r++)
                {
                    for (var c = 0; c < columns.Count; c++)
                    {
                        rows[r].TryGetValue(columns[c].FieldKey, out var value);
                        sheet.Cell(r + 2, c + 1).Value = value ?? string.Empty;
                    }
                }
            }

            var lastCol = Math.Max(columns.Count, 1);
            var lastRow = Math.Max((rows?.Count ?? 0) + 1, 1);
            var range = sheet.Range(1, 1, lastRow, lastCol);
            range.SetAutoFilter();
            sheet.SheetView.FreezeRows(1);
            sheet.Columns().AdjustToContents();

            var meta = workbook.Worksheets.Add(MetaSheetName);
            meta.Cell(1, 1).Value = "signature";
            meta.Cell(1, 2).Value = signature;
            meta.Visibility = XLWorksheetVisibility.VeryHidden;

            workbook.CustomProperties.Add(SignatureProperty, signature);

            using var ms = new MemoryStream();
            workbook.SaveAs(ms);
            return ms.ToArray();
        }

        private async Task<MemberExcelPreviewDto> AnalyzeAsync(
            MemberExcelScope scope,
            int? meetingId,
            Stream fileStream,
            string fileName,
            string culture,
            bool commit,
            MemberExcelDuplicateMode duplicateMode)
        {
            var preview = new MemberExcelPreviewDto();
            if (!IsSupportedExcelFile(fileName))
            {
                preview.IsTemplateValid = false;
                preview.TemplateError = "Invalid file. Please upload an Excel file (.xlsx or .xls).";
                return preview;
            }

            var columns = await BuildColumnsAsync(scope, meetingId, culture);
            var expectedSignature = await BuildSignatureAsync(scope, meetingId, columns);

            await using var buffer = new MemoryStream();
            await fileStream.CopyToAsync(buffer);
            buffer.Position = 0;

            string? actualSignature = null;
            List<string> headers;
            List<Dictionary<string, string?>> dataRows;

            try
            {
                (headers, dataRows, actualSignature) = ReadWorkbook(buffer);
            }
            catch (Exception)
            {
                preview.IsTemplateValid = false;
                preview.TemplateError = "Invalid file. Please upload an Excel file (.xlsx or .xls).";
                return preview;
            }

            if (string.IsNullOrWhiteSpace(actualSignature)
                || !string.Equals(actualSignature, expectedSignature, StringComparison.OrdinalIgnoreCase))
            {
                preview.IsTemplateValid = false;
                preview.TemplateError =
                    "This Excel template is outdated. Please download the latest template.";
                return preview;
            }

            var expectedHeaders = columns.Select(c => c.Header).ToList();
            if (headers.Count != expectedHeaders.Count
                || headers.Where((h, i) => !string.Equals(h, expectedHeaders[i], StringComparison.Ordinal))
                    .Any())
            {
                preview.IsTemplateValid = false;
                preview.TemplateError =
                    "This Excel template is outdated. Please download the latest template.";
                preview.InvalidColumns = headers
                    .Where(h => !expectedHeaders.Contains(h, StringComparer.Ordinal))
                    .ToList();
                preview.MissingRequiredColumns = expectedHeaders
                    .Where(h => !headers.Contains(h, StringComparer.Ordinal))
                    .ToList();
                return preview;
            }

            preview.IsTemplateValid = true;
            preview.TotalRows = dataRows.Count;

            var headerToKey = columns.ToDictionary(c => c.Header, c => c.FieldKey, StringComparer.Ordinal);
            Meeting? scopedMeeting = null;
            Dictionary<string, Classroom> classroomsByName = new(StringComparer.OrdinalIgnoreCase);
            Dictionary<string, Meeting> meetingsByName = new(StringComparer.OrdinalIgnoreCase);

            if (scope == MemberExcelScope.Meeting)
            {
                scopedMeeting = await _meetingRepository.GetByIdAsync(meetingId!.Value)
                    ?? throw new NotFoundException($"Meeting with id {meetingId} was not found.");
                if (scopedMeeting.HasClassrooms)
                {
                    foreach (var c in await _classroomRepository.GetByMeetingIdAsync(meetingId))
                    {
                        if (!string.IsNullOrWhiteSpace(c.Name))
                            classroomsByName[c.Name.Trim()] = c;
                    }
                }
            }
            else
            {
                var churchId = _tenantContext.ChurchId!.Value;
                foreach (var m in await _meetingRepository.GetByChurchIdAsync(churchId))
                {
                    if (!string.IsNullOrWhiteSpace(m.Name))
                        meetingsByName[m.Name.Trim()] = m;
                }
            }

            var existing = await LoadMembersForExportAsync(scope, meetingId);
            var byFullName = existing
                .GroupBy(NormalizeFullName)
                .Where(g => !string.IsNullOrWhiteSpace(g.Key))
                .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);

            // Re-parse rows into keyed maps
            var keyedRows = new List<(int RowNumber, Dictionary<string, string?> Values)>();
            for (var i = 0; i < dataRows.Count; i++)
            {
                var excelRow = dataRows[i];
                var keyed = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase);
                foreach (var pair in excelRow)
                {
                    if (headerToKey.TryGetValue(pair.Key, out var fieldKey))
                        keyed[fieldKey] = pair.Value;
                }

                keyedRows.Add((i + 2, keyed)); // Excel row (header is 1)
            }

            foreach (var (rowNumber, values) in keyedRows)
            {
                var name1 = values.GetValueOrDefault("name1")?.Trim();
                var name2 = values.GetValueOrDefault("name2")?.Trim();
                var name3 = values.GetValueOrDefault("name3")?.Trim();
                var displayName = string.Join(" ", new[] { name1, name2, name3 }
                    .Where(n => !string.IsNullOrWhiteSpace(n)));

                if (string.IsNullOrWhiteSpace(name1)
                    || string.IsNullOrWhiteSpace(name2)
                    || string.IsNullOrWhiteSpace(name3))
                {
                    preview.InvalidRows.Add(new MemberExcelRowIssueDto
                    {
                        RowNumber = rowNumber,
                        MemberName = displayName,
                        Reason = $"Row {rowNumber}: First Name, Middle Name, and Last Name are all required."
                    });
                    continue;
                }

                int? targetMeetingId = meetingId;
                int? classroomId = null;
                Meeting? rowMeeting = scopedMeeting;

                if (scope == MemberExcelScope.Church)
                {
                    var meetingName = values.GetValueOrDefault(MeetingFieldKey)?.Trim();
                    if (string.IsNullOrWhiteSpace(meetingName)
                        || !meetingsByName.TryGetValue(meetingName, out rowMeeting))
                    {
                        preview.InvalidRows.Add(new MemberExcelRowIssueDto
                        {
                            RowNumber = rowNumber,
                            MemberName = displayName,
                            Reason = $"Row {rowNumber}: Meeting \"{meetingName}\" does not exist."
                        });
                        continue;
                    }

                    targetMeetingId = rowMeeting.Id;
                }

                if (rowMeeting!.HasClassrooms)
                {
                    var groupName = values.GetValueOrDefault(ClassroomFieldKey)?.Trim();
                    Dictionary<string, Classroom> classMap = classroomsByName;
                    if (scope == MemberExcelScope.Church)
                    {
                        classMap = new Dictionary<string, Classroom>(StringComparer.OrdinalIgnoreCase);
                        foreach (var c in await _classroomRepository.GetByMeetingIdAsync(rowMeeting.Id))
                        {
                            if (!string.IsNullOrWhiteSpace(c.Name))
                                classMap[c.Name.Trim()] = c;
                        }
                    }

                    if (string.IsNullOrWhiteSpace(groupName) || !classMap.TryGetValue(groupName, out var classroom))
                    {
                        preview.InvalidRows.Add(new MemberExcelRowIssueDto
                        {
                            RowNumber = rowNumber,
                            MemberName = displayName,
                            Reason =
                                $"Row {rowNumber}: Group \"{groupName}\" does not exist in this Meeting."
                        });
                        continue;
                    }

                    classroomId = classroom.Id;
                }

                var fullKey = NormalizeFullName(name1, name2, name3);
                if (byFullName.TryGetValue(fullKey, out var existingMember))
                {
                    if (!commit)
                    {
                        preview.DuplicateRows.Add(new MemberExcelRowIssueDto
                        {
                            RowNumber = rowNumber,
                            MemberName = displayName,
                            ExistingMemberId = existingMember.Id,
                            Reason = $"Row {rowNumber}: Member \"{displayName}\" already exists."
                        });
                        continue;
                    }

                    if (duplicateMode == MemberExcelDuplicateMode.Skip)
                    {
                        preview.DuplicateRows.Add(new MemberExcelRowIssueDto
                        {
                            RowNumber = rowNumber,
                            MemberName = displayName,
                            ExistingMemberId = existingMember.Id,
                            Reason = "skipped"
                        });
                        continue;
                    }

                    try
                    {
                        await ApplyUpdateAsync(existingMember.Id, values, classroomId);
                        preview.ValidRows.Add(new MemberExcelRowIssueDto
                        {
                            RowNumber = rowNumber,
                            MemberName = displayName,
                            ExistingMemberId = existingMember.Id,
                            Reason = "updated"
                        });
                    }
                    catch (Exception ex)
                    {
                        preview.DuplicateRows.Add(new MemberExcelRowIssueDto
                        {
                            RowNumber = rowNumber,
                            MemberName = displayName,
                            ExistingMemberId = existingMember.Id,
                            Reason = $"failed: {ex.Message}"
                        });
                    }

                    continue;
                }

                if (!commit)
                {
                    preview.ValidRows.Add(new MemberExcelRowIssueDto
                    {
                        RowNumber = rowNumber,
                        MemberName = displayName,
                        Reason = "ok"
                    });
                    continue;
                }

                try
                {
                    var newId = await ApplyCreateAsync(values, classroomId, targetMeetingId!.Value, rowMeeting);
                    byFullName[fullKey] = new MemberReadDTO
                    {
                        Id = newId,
                        Name1 = name1,
                        Name2 = name2,
                        Name3 = name3,
                        FullName = displayName
                    };
                    preview.ValidRows.Add(new MemberExcelRowIssueDto
                    {
                        RowNumber = rowNumber,
                        MemberName = displayName,
                        ExistingMemberId = newId,
                        Reason = "imported"
                    });
                }
                catch (Exception ex)
                {
                    preview.InvalidRows.Add(new MemberExcelRowIssueDto
                    {
                        RowNumber = rowNumber,
                        MemberName = displayName,
                        Reason = $"Row {rowNumber}: {ex.Message}"
                    });
                }
            }

            return preview;
        }

        private async Task<int> ApplyCreateAsync(
            Dictionary<string, string?> values,
            int? classroomId,
            int meetingId,
            Meeting meeting)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);
            var add = new MemberAddDTO
            {
                Name1 = values.GetValueOrDefault("name1")?.Trim(),
                Name2 = values.GetValueOrDefault("name2")?.Trim(),
                Name3 = values.GetValueOrDefault("name3")?.Trim(),
                Gender = NullIfEmpty(values.GetValueOrDefault("gender")),
                Address = NullIfEmpty(values.GetValueOrDefault("address")),
                DateOfBirth = ParseDate(values.GetValueOrDefault("dateOfBirth")) ?? today,
                JoiningDate = ParseDate(values.GetValueOrDefault("joiningDate")) ?? today,
                SpiritualDateOfBirth = ParseDate(values.GetValueOrDefault("spiritualDateOfBirth")),
                HaveBrothers = ParseBool(values.GetValueOrDefault("haveBrothers")),
                BrothersNames = ParseStringList(values.GetValueOrDefault("brothersNames")),
                Notes = ParseStringList(values.GetValueOrDefault("notes")),
                PhoneNumbers = ParsePhones(values.GetValueOrDefault("phoneNumbers"))
            };

            int id;
            if (meeting.HasClassrooms)
            {
                if (classroomId is null or <= 0)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Classroom"] = new[] { "Classroom is required for this meeting." }
                    });
                id = await _memberManager.AddAsync(add, classroomId, meetingId);
            }
            else
            {
                id = await _memberManager.AddAsync(add, classroomId: null, meetingId: meetingId);
            }

            await SaveCustomAndExtraFieldsAsync(id, values);
            return id;
        }

        private async Task ApplyUpdateAsync(
            int memberId,
            Dictionary<string, string?> values,
            int? classroomId)
        {
            var update = new MemberUpdateDTO { Id = memberId };

            if (HasText(values, "name1")) update.Name1 = values["name1"]!.Trim();
            if (HasText(values, "name2")) update.Name2 = values["name2"]!.Trim();
            if (HasText(values, "name3")) update.Name3 = values["name3"]!.Trim();
            if (HasText(values, "gender")) update.Gender = values["gender"]!.Trim();
            if (HasText(values, "address")) update.Address = values["address"]!.Trim();

            var dob = ParseDate(values.GetValueOrDefault("dateOfBirth"));
            if (dob.HasValue) update.DateOfBirth = dob;
            var join = ParseDate(values.GetValueOrDefault("joiningDate"));
            if (join.HasValue) update.JoiningDate = join;
            var spiritual = ParseDate(values.GetValueOrDefault("spiritualDateOfBirth"));
            if (spiritual.HasValue) update.SpiritualDateOfBirth = spiritual;

            var discipline = ParseBool(values.GetValueOrDefault("isDiscipline"));
            if (discipline.HasValue) update.IsDiscipline = discipline;
            var haveBrothers = ParseBool(values.GetValueOrDefault("haveBrothers"));
            if (haveBrothers.HasValue) update.HaveBrothers = haveBrothers;

            if (HasText(values, "brothersNames"))
                update.BrothersNames = ParseStringList(values["brothersNames"]);
            if (HasText(values, "notes"))
                update.Notes = ParseStringList(values["notes"]);
            if (HasText(values, "phoneNumbers"))
                update.PhoneNumbers = ParsePhones(values["phoneNumbers"]);
            if (classroomId.HasValue)
                update.ClassroomId = classroomId;

            await _memberManager.UpdateAsync(update);
            await SaveCustomAndExtraFieldsAsync(memberId, values);
        }

        private async Task SaveCustomAndExtraFieldsAsync(int memberId, Dictionary<string, string?> values)
        {
            var schema = await _formManager.GetFormSchemaAsync(
                CustomFieldEntityNames.Member,
                EntityFormMode.Edit);

            var fields = new List<UnifiedFieldValueDto>();
            foreach (var field in schema.Fields)
            {
                if (ExcludedFieldKeys.Contains(field.FieldKey))
                    continue;
                if (field.FieldKey is MeetingFieldKey or ClassroomFieldKey)
                    continue;
                if (!values.TryGetValue(field.FieldKey, out var raw) || string.IsNullOrWhiteSpace(raw))
                    continue;

                // Built-ins already applied via Add/Update; still persist custom defs and syncable keys.
                if (field.IsBuiltIn && RequiredNameKeys.Contains(field.FieldKey))
                    continue;

                var normalized = NormalizeFieldValueForForm(field, raw);
                if (normalized == null)
                    continue;

                fields.Add(new UnifiedFieldValueDto
                {
                    FieldKey = field.FieldKey,
                    Value = normalized
                });
            }

            if (fields.Count == 0)
                return;

            await _formManager.SaveFormDataAsync(
                CustomFieldEntityNames.Member,
                memberId,
                new SaveEntityFormDto { Fields = fields });
        }

        private static string? NormalizeFieldValueForForm(UnifiedFieldDefinitionDto field, string raw)
        {
            raw = raw.Trim();
            return field.DataType switch
            {
                CustomFieldDataType.Boolean => ParseBool(raw)?.ToString() ?? raw,
                CustomFieldDataType.Date or CustomFieldDataType.DateTime =>
                    ParseDate(raw)?.ToString("yyyy-MM-dd") ?? raw,
                CustomFieldDataType.Json =>
                    field.FieldKey is "phoneNumbers"
                        ? JsonSerializer.Serialize(ParsePhones(raw) ?? new List<MemberContactDTO>())
                        : JsonSerializer.Serialize(ParseStringList(raw) ?? new List<string>()),
                _ => raw
            };
        }

        private async Task<List<MemberReadDTO>> LoadMembersForExportAsync(
            MemberExcelScope scope,
            int? meetingId)
        {
            if (scope == MemberExcelScope.Church)
            {
                var all = await _memberManager.GetAllAsync();
                return all.ToList();
            }

            if (_currentUser.IsInRole("Admin") || _currentUser.IsInRole("SuperAdmin"))
            {
                try
                {
                    return (await _memberManager.GetAllMembersByMeetingIdAsync(meetingId!.Value)).ToList();
                }
                catch
                {
                    return (await _memberManager.GetByMeetingIdAsync(meetingId!.Value)).ToList();
                }
            }

            return (await _memberManager.GetAssignedByMeetingIdAsync(meetingId!.Value)).ToList();
        }

        private static (List<string> Headers, List<Dictionary<string, string?>> Rows, string? Signature)
            ReadWorkbook(Stream stream)
        {
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
            stream.Position = 0;

            // Prefer ClosedXML for xlsx signature + headers
            try
            {
                using var workbook = new XLWorkbook(stream);
                var signature = workbook.CustomProperties
                    .FirstOrDefault(p => p.Name == SignatureProperty)?.Value?.ToString();

                if (string.IsNullOrWhiteSpace(signature)
                    && workbook.Worksheets.TryGetWorksheet(MetaSheetName, out var meta))
                {
                    signature = meta.Cell(1, 2).GetString();
                }

                var sheet = workbook.Worksheets.First(ws =>
                    !string.Equals(ws.Name, MetaSheetName, StringComparison.OrdinalIgnoreCase));

                var headerRow = sheet.Row(1);
                var lastCol = headerRow.LastCellUsed()?.Address.ColumnNumber ?? 0;
                var headers = new List<string>();
                for (var c = 1; c <= lastCol; c++)
                    headers.Add(headerRow.Cell(c).GetString().Trim());

                var rows = new List<Dictionary<string, string?>>();
                var lastRow = sheet.LastRowUsed()?.RowNumber() ?? 1;
                for (var r = 2; r <= lastRow; r++)
                {
                    var dict = new Dictionary<string, string?>(StringComparer.Ordinal);
                    var empty = true;
                    for (var c = 1; c <= headers.Count; c++)
                    {
                        var text = sheet.Cell(r, c).GetFormattedString()?.Trim();
                        if (!string.IsNullOrWhiteSpace(text))
                            empty = false;
                        dict[headers[c - 1]] = text;
                    }

                    if (!empty)
                        rows.Add(dict);
                }

                return (headers, rows, signature);
            }
            catch
            {
                stream.Position = 0;
                using var reader = ExcelReaderFactory.CreateReader(stream);
                var result = reader.AsDataSet(new ExcelDataSetConfiguration
                {
                    ConfigureDataTable = _ => new ExcelDataTableConfiguration { UseHeaderRow = true }
                });

                string? signature = null;
                var table = result.Tables.Cast<System.Data.DataTable>()
                    .FirstOrDefault(t => !string.Equals(t.TableName, MetaSheetName, StringComparison.OrdinalIgnoreCase))
                    ?? result.Tables[0];

                var metaTable = result.Tables.Cast<System.Data.DataTable>()
                    .FirstOrDefault(t => string.Equals(t.TableName, MetaSheetName, StringComparison.OrdinalIgnoreCase));
                if (metaTable is { Rows.Count: > 0, Columns.Count: >= 2 })
                    signature = metaTable.Rows[0][1]?.ToString();

                var headers = table.Columns.Cast<System.Data.DataColumn>()
                    .Select(c => c.ColumnName.Trim())
                    .ToList();

                var rows = new List<Dictionary<string, string?>>();
                foreach (System.Data.DataRow row in table.Rows)
                {
                    var dict = new Dictionary<string, string?>(StringComparer.Ordinal);
                    var empty = true;
                    foreach (var header in headers)
                    {
                        var text = row[header]?.ToString()?.Trim();
                        if (!string.IsNullOrWhiteSpace(text))
                            empty = false;
                        dict[header] = text;
                    }

                    if (!empty)
                        rows.Add(dict);
                }

                return (headers, rows, signature);
            }
        }

        private static bool IsSupportedExcelFile(string? fileName)
        {
            if (string.IsNullOrWhiteSpace(fileName))
                return false;
            var ext = Path.GetExtension(fileName).ToLowerInvariant();
            return ext is ".xlsx" or ".xls";
        }

        private static string NormalizeFullName(MemberReadDTO m) =>
            NormalizeFullName(m.Name1, m.Name2, m.Name3);

        private static string NormalizeFullName(string? n1, string? n2, string? n3) =>
            string.Join(" ", new[] { n1, n2, n3 }
                    .Select(n => n?.Trim())
                    .Where(n => !string.IsNullOrWhiteSpace(n)))
                .ToLowerInvariant();

        private static string? NullIfEmpty(string? value) =>
            string.IsNullOrWhiteSpace(value) ? null : value.Trim();

        private static bool HasText(Dictionary<string, string?> values, string key) =>
            values.TryGetValue(key, out var v) && !string.IsNullOrWhiteSpace(v);

        private static DateOnly? ParseDate(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw))
                return null;
            if (DateOnly.TryParse(raw.Trim(), CultureInfo.InvariantCulture, DateTimeStyles.None, out var d))
                return d;
            if (DateTime.TryParse(raw.Trim(), CultureInfo.InvariantCulture, DateTimeStyles.AssumeLocal, out var dt))
                return DateOnly.FromDateTime(dt);
            if (double.TryParse(raw.Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out var oa))
            {
                try
                {
                    return DateOnly.FromDateTime(DateTime.FromOADate(oa));
                }
                catch
                {
                    return null;
                }
            }

            return null;
        }

        private static bool? ParseBool(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw))
                return null;
            var v = raw.Trim();
            if (bool.TryParse(v, out var b))
                return b;
            if (v is "1" or "yes" or "y" or "true" or "نعم")
                return true;
            if (v is "0" or "no" or "n" or "false" or "لا")
                return false;
            return null;
        }

        private static List<string>? ParseStringList(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw))
                return null;
            var trimmed = raw.Trim();
            if (trimmed.StartsWith('['))
            {
                try
                {
                    return JsonSerializer.Deserialize<List<string>>(trimmed);
                }
                catch
                {
                    // fall through
                }
            }

            return trimmed.Split(new[] { ',', ';', '|', '\n' }, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .ToList();
        }

        private static List<MemberContactDTO>? ParsePhones(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw))
                return null;
            var trimmed = raw.Trim();
            if (trimmed.StartsWith('['))
            {
                try
                {
                    return JsonSerializer.Deserialize<List<MemberContactDTO>>(
                        trimmed,
                        new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                }
                catch
                {
                    // fall through
                }
            }

            var phones = trimmed.Split(new[] { ',', ';', '|', '\n' }, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            return phones
                .Select(p => new MemberContactDTO { PhoneNumber = p, Relation = "Other" })
                .ToList();
        }

        private static string? FormatExportValue(UnifiedFieldDto field)
        {
            if (string.IsNullOrWhiteSpace(field.Value))
                return null;

            if (field.DataType == CustomFieldDataType.Json
                && field.FieldKey.Equals("phoneNumbers", StringComparison.OrdinalIgnoreCase))
            {
                try
                {
                    var phones = JsonSerializer.Deserialize<List<MemberContactDTO>>(
                        field.Value,
                        new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    if (phones is { Count: > 0 })
                        return string.Join(", ", phones.Select(p => p.PhoneNumber).Where(p => !string.IsNullOrWhiteSpace(p)));
                }
                catch
                {
                    return field.Value;
                }
            }

            if (field.DataType == CustomFieldDataType.Json)
            {
                try
                {
                    var list = JsonSerializer.Deserialize<List<string>>(field.Value);
                    if (list is { Count: > 0 })
                        return string.Join(", ", list);
                }
                catch
                {
                    return field.Value;
                }
            }

            return field.Value;
        }
    }
}
