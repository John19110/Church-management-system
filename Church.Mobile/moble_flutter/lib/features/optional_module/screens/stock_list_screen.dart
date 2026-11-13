import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../models/optional_module_models.dart';
import '../providers/optional_module_providers.dart';

class StockListScreen extends ConsumerStatefulWidget {
  const StockListScreen({super.key});

  @override
  ConsumerState<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends ConsumerState<StockListScreen> {
  final _search = TextEditingController();
  String _query = '';
  final Map<int, int> _optimisticAmounts = {};
  final Set<int> _pendingIds = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _displayAmount(StockItemDto item) =>
      _optimisticAmounts[item.id] ?? item.amount;

  Future<void> _changeAmount(StockItemDto item, int delta) async {
    if (_pendingIds.contains(item.id)) return;

    final current = _displayAmount(item);
    final next = current + delta;
    if (next < 0) return;

    setState(() {
      _optimisticAmounts[item.id] = next;
      _pendingIds.add(item.id);
    });

    final l10n = AppLocalizations.of(context);
    final repo = ref.read(stockItemRepositoryProvider);

    try {
      final result = delta > 0
          ? await repo.increase(item.id)
          : await repo.decrease(item.id);
      if (!mounted) return;
      setState(() {
        _optimisticAmounts[item.id] = result.amount;
        _pendingIds.remove(item.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optimisticAmounts[item.id] = current;
        _pendingIds.remove(item.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(e, l10n))),
      );
    }
  }

  Future<void> _confirmDelete(StockItemDto item) async {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.locale.languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteStockItem),
        content: Text(
          l10n.confirmDeleteStockItem(item.displayName(isArabic)),
        ),
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

    try {
      await ref.read(stockItemRepositoryProvider).deleteItem(item.id);
      bumpStockItems(ref);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(e, l10n))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final canManage = AuthRoleUtils.canManageCustomFields(role) ||
        role == 'servant';
    final stockEnabled = ref.watch(isStockModuleEnabledProvider);
    final itemsAsync = ref.watch(stockItemsProvider(_query));
    final isArabic = l10n.locale.languageCode == 'ar';

    return stockEnabled.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.stockModule)),
        body: const LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.stockModule)),
        body: AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => bumpOptionalModules(ref),
        ),
      ),
      data: (enabled) {
        if (!enabled) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.stockModule)),
            body: Center(child: Text(l10n.moduleNotEnabled)),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(l10n.stockModule)),
          floatingActionButton: canManage
              ? FloatingActionButton(
                  onPressed: () => context.push(AppRoutes.stockNew),
                  child: const Icon(Icons.add),
                )
              : null,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppSearchField(
                  controller: _search,
                  hint: l10n.search,
                  onChanged: (value) =>
                      setState(() => _query = value.trim()),
                ),
              ),
              Expanded(
                child: itemsAsync.when(
                  loading: () => const LoadingWidget(useSkeleton: true),
                  error: (e, _) => AppErrorWidget(
                    message: userFriendlyMessage(e, l10n),
                    onRetry: () => bumpStockItems(ref),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return EmptyWidget(
                        message: l10n.noStockItemsYet,
                        title: l10n.stockModule,
                        actionLabel: canManage ? l10n.addStockItem : null,
                        onAction: canManage
                            ? () => context.push(AppRoutes.stockNew)
                            : null,
                        icon: Icons.inventory_2_outlined,
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => bumpStockItems(ref),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final amount = _displayAmount(item);
                          final pending = _pendingIds.contains(item.id);
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  AppNetworkAvatar(
                                    imageUrl: item.imageUrl,
                                    radius: 28,
                                    placeholder: const Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: InkWell(
                                      onTap: canManage
                                          ? () => context.push(
                                                '${AppRoutes.stock}/${item.id}/edit',
                                              )
                                          : null,
                                      onLongPress: canManage
                                          ? () => _confirmDelete(item)
                                          : null,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.displayName(isArabic),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          if ((item.displayDescription(
                                                      isArabic) ??
                                                  '')
                                              .trim()
                                              .isNotEmpty)
                                            Text(
                                              item.displayDescription(
                                                    isArabic,
                                                  )!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  _AmountStepper(
                                    amount: amount,
                                    busy: pending,
                                    enabled: canManage,
                                    onDecrease: () =>
                                        _changeAmount(item, -1),
                                    onIncrease: () =>
                                        _changeAmount(item, 1),
                                  ),
                                  if (canManage)
                                    IconButton(
                                      tooltip: l10n.editStockItem,
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => context.push(
                                        '${AppRoutes.stock}/${item.id}/edit',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AmountStepper extends StatelessWidget {
  final int amount;
  final bool busy;
  final bool enabled;
  final void Function() onDecrease;
  final void Function() onIncrease;

  const _AmountStepper({
    required this.amount,
    required this.busy,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrease = enabled && !busy && amount > 0;
    final canIncrease = enabled && !busy;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: canDecrease ? onDecrease : null,
          icon: const Icon(Icons.remove),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(
          width: 40,
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Text(
                  '$amount',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
        ),
        IconButton.filledTonal(
          onPressed: canIncrease ? onIncrease : null,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
