import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../models/member_excel_models.dart';
import '../repositories/member_excel_repository.dart';
import '../utils/member_excel_file_picker.dart';
import '../utils/member_excel_file_saver.dart';

/// Meeting-level or church-wide Member Excel Import & Export.
class MemberExcelScreen extends ConsumerStatefulWidget {
  final bool churchWide;
  final int? meetingId;
  final String? meetingName;

  const MemberExcelScreen({
    super.key,
    required this.churchWide,
    this.meetingId,
    this.meetingName,
  });

  @override
  ConsumerState<MemberExcelScreen> createState() => _MemberExcelScreenState();
}

class _MemberExcelScreenState extends ConsumerState<MemberExcelScreen> {
  bool _busy = false;
  MemberExcelPreviewDto? _preview;
  MemberExcelImportResultDto? _result;
  String? _pickedFileName;
  List<int>? _pickedBytes;
  List<MemberExcelExportFieldDto> _exportFields = const [];
  final Set<String> _selectedExportKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExportFields());
  }

  Future<void> _loadExportFields() async {
    final l10n = AppLocalizations.of(context);
    final lang = ref.read(localeProvider).languageCode;
    try {
      final fields = await ref.read(memberExcelRepositoryProvider).getExportFields(
            churchWide: widget.churchWide,
            meetingId: widget.meetingId,
            languageCode: lang,
          );
      if (!mounted) return;
      setState(() {
        _exportFields = fields;
        _selectedExportKeys
          ..clear()
          ..addAll(fields.map((f) => f.fieldKey));
      });
    } catch (e) {
      if (!mounted) return;
      cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
    }
  }

  Future<void> _withBusy(Future<void> Function() action) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishExcelSave(
    MemberExcelSaveResult saved,
    String successMessage,
  ) async {
    if (!mounted) return;
    if (!saved.needsConfirmation) {
      cw.showSuccessSnackbar(context, successMessage);
      return;
    }

    final l10n = AppLocalizations.of(context);
    final url = saved.downloadUrl;
    if (url == null || url.isEmpty) {
      cw.showErrorSnackbar(context, l10n.memberExcelSaveFailed);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.memberExcelFileReadyTitle),
          content: Text(l10n.memberExcelFileReadyBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                confirmMemberExcelDownload(url, saved.fileName);
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(l10n.memberExcelSaveFile),
            ),
          ],
        );
      },
    );

    releaseMemberExcelDownloadUrl(url);
    if (!mounted) return;
    if (confirmed == true) {
      cw.showSuccessSnackbar(context, successMessage);
    }
  }

  Future<void> _downloadTemplate() async {
    final l10n = AppLocalizations.of(context);
    final lang = ref.read(localeProvider).languageCode;
    // Chromium desktop: open Save dialog in this click (keeps user gesture).
    final saveHandle = await beginMemberExcelSave(
      suggestedFileName: widget.churchWide
          ? 'members-template-church.xlsx'
          : 'members-template-meeting.xlsx',
    );
    if (identical(saveHandle, memberExcelSaveCancelled)) return;
    await _withBusy(() async {
      final file = await ref.read(memberExcelRepositoryProvider).downloadTemplate(
            churchWide: widget.churchWide,
            meetingId: widget.meetingId,
            languageCode: lang,
          );
      final saved = await saveMemberExcelFile(
        file.bytes,
        file.fileName,
        saveHandle: saveHandle,
      );
      await _finishExcelSave(saved, l10n.memberExcelTemplateDownloaded);
    });
  }

  Future<void> _pickAndPreview() async {
    final l10n = AppLocalizations.of(context);
    final lang = ref.read(localeProvider).languageCode;

    MemberExcelPickedFile? picked;
    try {
      picked = await pickMemberExcelFile();
    } catch (e) {
      if (!mounted) return;
      cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      return;
    }

    if (picked == null) return;
    final bytes = picked.bytes;
    final name = picked.fileName;
    final lower = name.toLowerCase();
    if (bytes.isEmpty ||
        !(lower.endsWith('.xlsx') || lower.endsWith('.xls'))) {
      if (!mounted) return;
      cw.showErrorSnackbar(context, l10n.memberExcelInvalidFile);
      return;
    }

    await _withBusy(() async {
      final preview = await ref.read(memberExcelRepositoryProvider).previewImport(
            churchWide: widget.churchWide,
            meetingId: widget.meetingId,
            languageCode: lang,
            fileName: name,
            bytes: bytes,
          );
      if (!mounted) return;
      setState(() {
        _pickedFileName = name;
        _pickedBytes = bytes;
        _preview = preview;
        _result = null;
      });
    });
  }

  Future<void> _confirmAndUpdateDuplicates() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await cw.showConfirmDialog(
      context,
      title: l10n.memberExcelConfirmUpdateTitle,
      content: l10n.memberExcelConfirmUpdateBody,
      confirmText: l10n.memberExcelUpdateDuplicates,
    );
    if (!confirmed) return;
    await _commitImport('Update');
  }

  Future<void> _commitImport(String duplicateMode) async {
    final l10n = AppLocalizations.of(context);
    final lang = ref.read(localeProvider).languageCode;
    final bytes = _pickedBytes;
    final name = _pickedFileName;
    if (bytes == null || name == null) return;

    await _withBusy(() async {
      final result = await ref.read(memberExcelRepositoryProvider).importMembers(
            churchWide: widget.churchWide,
            meetingId: widget.meetingId,
            languageCode: lang,
            fileName: name,
            bytes: bytes,
            duplicateMode: duplicateMode,
          );
      if (!mounted) return;
      setState(() => _result = result);
      cw.showSuccessSnackbar(context, l10n.memberExcelImportCompleted);
    });
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    final lang = ref.read(localeProvider).languageCode;
    if (_selectedExportKeys.isEmpty) {
      cw.showErrorSnackbar(context, l10n.memberExcelExportNoFields);
      return;
    }
    final saveHandle = await beginMemberExcelSave(
      suggestedFileName: widget.churchWide
          ? 'members-export-church.xlsx'
          : 'members-export-meeting.xlsx',
    );
    if (identical(saveHandle, memberExcelSaveCancelled)) return;
    await _withBusy(() async {
      final file = await ref.read(memberExcelRepositoryProvider).exportMembers(
            churchWide: widget.churchWide,
            meetingId: widget.meetingId,
            languageCode: lang,
            fields: _selectedExportKeys.toList(),
          );
      final saved = await saveMemberExcelFile(
        file.bytes,
        file.fileName,
        saveHandle: saveHandle,
      );
      await _finishExcelSave(saved, l10n.memberExcelExportDownloaded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.churchWide
        ? l10n.memberExcelChurchTitle
        : (widget.meetingName?.trim().isNotEmpty == true
            ? '${l10n.memberExcelTitle} — ${widget.meetingName}'
            : l10n.memberExcelTitle);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.memberExcelInstructionsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(l10n.memberExcelInstructionsBody),
              const SizedBox(height: 8),
              Text(
                l10n.memberExcelNameRequiredHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.members,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _downloadTemplate,
                icon: const Icon(Icons.download_outlined),
                label: Text(l10n.memberExcelDownloadTemplate),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _pickAndPreview,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(l10n.memberExcelImportMembers),
              ),
              if (_preview != null) ...[
                const SizedBox(height: 16),
                _PreviewCard(
                  preview: _preview!,
                  fileName: _pickedFileName,
                  onSkipDuplicates: () => _commitImport('Skip'),
                  onUpdateDuplicates: () => _confirmAndUpdateDuplicates(),
                  busy: _busy,
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 16),
                _ResultCard(result: _result!),
              ],
              const SizedBox(height: 24),
              Text(
                l10n.memberExcelExportTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(l10n.memberExcelExportHint),
              const SizedBox(height: 8),
              if (_exportFields.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.memberExcelExportFieldsLoading,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ..._exportFields.map(
                (f) => CheckboxListTile(
                  dense: true,
                  value: _selectedExportKeys.contains(f.fieldKey),
                  title: Text(f.header),
                  onChanged: _busy
                      ? null
                      : (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedExportKeys.add(f.fieldKey);
                            } else {
                              _selectedExportKeys.remove(f.fieldKey);
                            }
                          });
                        },
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy || _selectedExportKeys.isEmpty ? null : _export,
                icon: const Icon(Icons.table_view_outlined),
                label: Text(l10n.memberExcelExportMembers),
              ),
            ],
          ),
          if (_busy)
            ColoredBox(
              color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.32),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final MemberExcelPreviewDto preview;
  final String? fileName;
  final void Function() onSkipDuplicates;
  final void Function() onUpdateDuplicates;
  final bool busy;

  const _PreviewCard({
    required this.preview,
    required this.fileName,
    required this.onSkipDuplicates,
    required this.onUpdateDuplicates,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (!preview.isTemplateValid) {
      return Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preview.templateError ?? l10n.memberExcelTemplateOutdated,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              if (preview.invalidColumns.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${l10n.memberExcelInvalidColumns}: ${preview.invalidColumns.join(', ')}',
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName ?? l10n.memberExcelImportPreview,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text('${l10n.memberExcelTotalRows}: ${preview.totalRows}'),
            Text('${l10n.memberExcelValidRows}: ${preview.validRows.length}'),
            Text(
              '${l10n.memberExcelDuplicateRows}: ${preview.duplicateRows.length}',
            ),
            Text(
              '${l10n.memberExcelInvalidRows}: ${preview.invalidRows.length}',
            ),
            if (preview.invalidRows.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...preview.invalidRows.take(8).map(
                    (r) => Text('• ${r.reason}', style: theme.textTheme.bodySmall),
                  ),
            ],
            if (preview.duplicateRows.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...preview.duplicateRows.take(8).map(
                    (r) => Text('• ${r.reason}', style: theme.textTheme.bodySmall),
                  ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: busy ||
                          (preview.validRows.isEmpty &&
                              preview.duplicateRows.isEmpty)
                      ? null
                      : onSkipDuplicates,
                  child: Text(l10n.memberExcelSkipDuplicates),
                ),
                FilledButton.tonal(
                  onPressed: busy || preview.duplicateRows.isEmpty
                      ? null
                      : onUpdateDuplicates,
                  child: Text(l10n.memberExcelUpdateDuplicates),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final MemberExcelImportResultDto result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.memberExcelImportCompleted,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text('${l10n.memberExcelTotalRows}: ${result.totalRows}'),
            Text(
              '${l10n.memberExcelSuccessfullyImported}: ${result.successfullyImported}',
            ),
            Text('${l10n.memberExcelUpdated}: ${result.updated}'),
            Text(
              '${l10n.memberExcelDuplicatesSkipped}: ${result.duplicatesSkipped}',
            ),
            Text('${l10n.memberExcelFailed}: ${result.failed}'),
            if (result.failures.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...result.failures.take(12).map(
                    (r) => Text('• ${r.reason}', style: theme.textTheme.bodySmall),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
