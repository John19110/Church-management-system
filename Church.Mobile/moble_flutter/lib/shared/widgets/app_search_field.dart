import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';

/// Rounded, filled search input matching the design language.
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const AppSearchField({
    super.key,
    this.controller,
    required this.hint,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasText = controller?.text.isNotEmpty ?? false;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search, color: palette.textTertiary),
        suffixIcon: hasText
            ? IconButton(
                icon: Icon(Icons.close, color: palette.textTertiary),
                onPressed: () {
                  controller?.clear();
                  onChanged?.call('');
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: palette.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 0),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Horizontal, scrollable segmented filter chips (All / By Grade / …).
class AppFilterChips extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const AppFilterChips({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? scheme.primary : palette.neutralSoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                options[index],
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? scheme.onPrimary : palette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}
