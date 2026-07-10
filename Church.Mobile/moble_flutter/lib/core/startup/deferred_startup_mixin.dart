import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defers heavy provider watches / API calls until after the first frame so the
/// initial route can paint before network I/O begins.
mixin DeferredStartupMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool _deferredReady = false;

  /// True after the first frame has been rendered.
  bool get deferredReady => _deferredReady;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _deferredReady = true);
    });
  }
}
