import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/media/picked_image.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../custom_field/widgets/dynamic_custom_fields_form.dart';
import '../../settings/providers/language_settings_providers.dart';
import '../../settings/widgets/translated_name_fields.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/widgets/unified_entity_photo_picker.dart'
    show pickUnifiedEntityPhoto;
import '../providers/optional_module_providers.dart';

class StockItemFormScreen extends ConsumerStatefulWidget {
  final int? itemId;

  const StockItemFormScreen({super.key, this.itemId});

  bool get isEditing => itemId != null;

  @override
  ConsumerState<StockItemFormScreen> createState() =>
      _StockItemFormScreenState();
}

class _StockItemFormScreenState extends ConsumerState<StockItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameEn = TextEditingController();
  final _nameAr = TextEditingController();
  final _descriptionEn = TextEditingController();
  final _descriptionAr = TextEditingController();
  final _amount = TextEditingController(text: '0');
  final _customFields = DynamicCustomFieldsController();

  PickedImage? _pickedImage;
  String? _existingImageUrl;
  bool _loading = false;
  bool _seeded = false;

  @override
  void dispose() {
    _nameEn.dispose();
    _nameAr.dispose();
    _descriptionEn.dispose();
    _descriptionAr.dispose();
    _amount.dispose();
    _customFields.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await pickUnifiedEntityPhoto(context);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    final church = TranslatedNameFields.resolveLanguages(
      church: ref.read(churchLanguagesProvider).valueOrNull,
      appLanguageCode: l10n.locale.languageCode,
    );
    TranslatedNameFields.mirrorArabicOnlyName(
      church: church,
      english: _nameEn,
      arabic: _nameAr,
    );

    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (amount < 0) {
      showErrorSnackbar(context, l10n.amountCannotBeNegative);
      return;
    }

    setState(() => _loading = true);
    final repo = ref.read(stockItemRepositoryProvider);

    try {
      late final int itemId;
      if (widget.isEditing) {
        final updated = await repo.updateItem(
          id: widget.itemId!,
          name: _nameEn.text.trim(),
          nameAr: _nameAr.text.trim().isEmpty ? null : _nameAr.text.trim(),
          description: _descriptionEn.text.trim().isEmpty
              ? null
              : _descriptionEn.text.trim(),
          descriptionAr: _descriptionAr.text.trim().isEmpty
              ? null
              : _descriptionAr.text.trim(),
          amount: amount,
        );
        itemId = updated.id;
      } else {
        final created = await repo.createItem(
          name: _nameEn.text.trim(),
          nameAr: _nameAr.text.trim().isEmpty ? null : _nameAr.text.trim(),
          description: _descriptionEn.text.trim().isEmpty
              ? null
              : _descriptionEn.text.trim(),
          descriptionAr: _descriptionAr.text.trim().isEmpty
              ? null
              : _descriptionAr.text.trim(),
          amount: amount,
        );
        itemId = created.id;
      }

      if (_pickedImage != null) {
        await repo.uploadImage(itemId, _pickedImage!);
      }

      await saveCustomFieldsForEntity(
        ref: ref,
        entityName: UnifiedEntityNames.stockItem,
        entityId: itemId,
        controller: _customFields,
      );

      bumpStockItems(ref);
      if (mounted) {
        showSuccessSnackbar(
          context,
          widget.isEditing ? l10n.stockItemUpdated : l10n.stockItemCreated,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _seedFromItem() {
    if (_seeded || !widget.isEditing) return;
    final async = ref.read(stockItemProvider(widget.itemId!));
    async.whenData((item) {
      if (_seeded) return;
      final l10n = AppLocalizations.of(context);
      final church = TranslatedNameFields.resolveLanguages(
        church: ref.read(churchLanguagesProvider).valueOrNull,
        appLanguageCode: l10n.locale.languageCode,
      );
      TranslatedNameFields.seedFromStored(
        church: church,
        english: _nameEn,
        arabic: _nameAr,
        displayName: item.name,
        displayNameAr: item.nameAr,
      );
      _descriptionEn.text = item.description ?? '';
      _descriptionAr.text = item.descriptionAr ?? '';
      _amount.text = '${item.amount}';
      _existingImageUrl = item.imageUrl;
      _seeded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final churchAsync = ref.watch(churchLanguagesProvider);

    if (widget.isEditing) {
      final itemAsync = ref.watch(stockItemProvider(widget.itemId!));
      return itemAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text(l10n.editStockItem)),
          body: const LoadingWidget(),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: Text(l10n.editStockItem)),
          body: AppErrorWidget(
            message: userFriendlyMessage(e, l10n),
            onRetry: () => bumpStockItems(ref),
          ),
        ),
        data: (_) {
          _seedFromItem();
          return _buildForm(l10n, churchAsync);
        },
      );
    }

    return _buildForm(l10n, churchAsync);
  }

  Widget _buildForm(AppLocalizations l10n, AsyncValue churchAsync) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? l10n.editStockItem : l10n.addStockItem,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Column(
                  children: [
                    Center(
                      child: _pickedImage != null
                          ? CircleAvatar(
                              radius: 48,
                              backgroundImage: _pickedImage!.memoryImage,
                            )
                          : AppNetworkAvatar(
                              imageUrl: _existingImageUrl,
                              radius: 48,
                              placeholder: const Icon(
                                Icons.inventory_2_outlined,
                                size: 36,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.tapToChangePhoto,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              churchAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => TranslatedNameFields(
                  english: _nameEn,
                  arabic: _nameAr,
                ),
                data: (_) => TranslatedNameFields(
                  english: _nameEn,
                  arabic: _nameAr,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _descriptionEn,
                label: l10n.stockDescription,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _descriptionAr,
                label: l10n.stockDescriptionAr,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _amount,
                label: l10n.stockAmount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.required;
                  }
                  final n = int.tryParse(value.trim());
                  if (n == null) return l10n.stockInvalidAmount;
                  if (n < 0) return l10n.amountCannotBeNegative;
                  return null;
                },
              ),
              DynamicCustomFieldsForm(
                entityName: UnifiedEntityNames.stockItem,
                entityId: widget.itemId,
                controller: _customFields,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: _loading ? null : _delete,
                  child: Text(l10n.deleteStockItem),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteStockItem),
        content: Text(l10n.confirmDeleteStockItem(_nameEn.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(stockItemRepositoryProvider).deleteItem(widget.itemId!);
      bumpStockItems(ref);
      if (mounted) {
        showSuccessSnackbar(context, l10n.stockItemDeleted);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
