class MemberExcelExportFieldDto {
  final String fieldKey;
  final String header;
  final bool selectedByDefault;

  const MemberExcelExportFieldDto({
    required this.fieldKey,
    required this.header,
    this.selectedByDefault = true,
  });

  factory MemberExcelExportFieldDto.fromJson(Map<String, dynamic> json) =>
      MemberExcelExportFieldDto(
        fieldKey: json['fieldKey'] as String? ?? '',
        header: json['header'] as String? ?? '',
        selectedByDefault: json['selectedByDefault'] as bool? ?? true,
      );
}

class MemberExcelRowIssueDto {
  final int rowNumber;
  final String? memberName;
  final String reason;
  final int? existingMemberId;

  const MemberExcelRowIssueDto({
    required this.rowNumber,
    this.memberName,
    required this.reason,
    this.existingMemberId,
  });

  factory MemberExcelRowIssueDto.fromJson(Map<String, dynamic> json) =>
      MemberExcelRowIssueDto(
        rowNumber: json['rowNumber'] as int? ?? 0,
        memberName: json['memberName'] as String?,
        reason: json['reason'] as String? ?? '',
        existingMemberId: json['existingMemberId'] as int?,
      );
}

class MemberExcelPreviewDto {
  final bool isTemplateValid;
  final String? templateError;
  final List<String> invalidColumns;
  final List<String> missingRequiredColumns;
  final int totalRows;
  final List<MemberExcelRowIssueDto> validRows;
  final List<MemberExcelRowIssueDto> duplicateRows;
  final List<MemberExcelRowIssueDto> invalidRows;

  const MemberExcelPreviewDto({
    required this.isTemplateValid,
    this.templateError,
    this.invalidColumns = const [],
    this.missingRequiredColumns = const [],
    this.totalRows = 0,
    this.validRows = const [],
    this.duplicateRows = const [],
    this.invalidRows = const [],
  });

  factory MemberExcelPreviewDto.fromJson(Map<String, dynamic> json) =>
      MemberExcelPreviewDto(
        isTemplateValid: json['isTemplateValid'] as bool? ?? false,
        templateError: json['templateError'] as String?,
        invalidColumns: (json['invalidColumns'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        missingRequiredColumns:
            (json['missingRequiredColumns'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        totalRows: json['totalRows'] as int? ?? 0,
        validRows: (json['validRows'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MemberExcelRowIssueDto.fromJson)
            .toList(),
        duplicateRows: (json['duplicateRows'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MemberExcelRowIssueDto.fromJson)
            .toList(),
        invalidRows: (json['invalidRows'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MemberExcelRowIssueDto.fromJson)
            .toList(),
      );
}

class MemberExcelImportResultDto {
  final int totalRows;
  final int successfullyImported;
  final int updated;
  final int duplicatesSkipped;
  final int failed;
  final List<MemberExcelRowIssueDto> failures;

  const MemberExcelImportResultDto({
    this.totalRows = 0,
    this.successfullyImported = 0,
    this.updated = 0,
    this.duplicatesSkipped = 0,
    this.failed = 0,
    this.failures = const [],
  });

  factory MemberExcelImportResultDto.fromJson(Map<String, dynamic> json) =>
      MemberExcelImportResultDto(
        totalRows: json['totalRows'] as int? ?? 0,
        successfullyImported: json['successfullyImported'] as int? ?? 0,
        updated: json['updated'] as int? ?? 0,
        duplicatesSkipped: json['duplicatesSkipped'] as int? ?? 0,
        failed: json['failed'] as int? ?? 0,
        failures: (json['failures'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MemberExcelRowIssueDto.fromJson)
            .toList(),
      );
}
