import 'package:church_app/core/theme/app_dimens.dart';
import 'package:church_app/shared/widgets/app_form_fields.dart';
import 'package:church_app/shared/widgets/app_form_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('appFieldScrollPadding', () {
    testWidgets('includes live viewInsets.bottom (any keyboard height)', (
      tester,
    ) async {
      late EdgeInsets padding;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 320)),
          child: Builder(
            builder: (context) {
              padding = appFieldScrollPadding(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(padding.bottom, AppSpacing.xl + 320);
      expect(padding.left, AppSpacing.md);
      expect(padding.right, AppSpacing.md);
      expect(padding.top, AppSpacing.md);
    });

    testWidgets('uses design gap only when viewInsets are consumed', (
      tester,
    ) async {
      late EdgeInsets padding;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) {
              padding = appFieldScrollPadding(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(padding.bottom, AppSpacing.xl);
    });

    testWidgets('adapts when keyboard inset changes', (tester) async {
      late EdgeInsets padding;

      Widget buildWithInset(double inset) {
        return MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: inset)),
          child: Builder(
            builder: (context) {
              padding = appFieldScrollPadding(context);
              return const SizedBox.shrink();
            },
          ),
        );
      }

      await tester.pumpWidget(buildWithInset(180));
      expect(padding.bottom, AppSpacing.xl + 180);

      await tester.pumpWidget(buildWithInset(420));
      expect(padding.bottom, AppSpacing.xl + 420);
    });
  });

  group('AppFormScrollView', () {
    Future<double> pumpAndReadMinHeight(
      WidgetTester tester, {
      required double viewportHeight,
    }) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(Size(400, viewportHeight));

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(400, viewportHeight)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 400,
              height: viewportHeight,
              child: const AppFormScrollView(
                padding: EdgeInsets.zero,
                child: SizedBox(height: 20),
              ),
            ),
          ),
        ),
      );

      final constrained = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(ConstrainedBox),
        ),
      );
      return constrained.constraints.minHeight;
    }

    testWidgets('gives child a viewport minHeight for keyboard scrolling', (
      tester,
    ) async {
      final minHeight = await pumpAndReadMinHeight(tester, viewportHeight: 800);
      expect(minHeight, 800 - AppSpacing.xl);
    });

    testWidgets('shrinks minHeight when viewport shrinks (keyboard open)', (
      tester,
    ) async {
      final minHeight = await pumpAndReadMinHeight(tester, viewportHeight: 350);
      expect(minHeight, 350 - AppSpacing.xl);
    });
  });

  group('AppTextField scrollPadding', () {
    testWidgets(
      'includes remaining viewInsets when scaffold has not consumed them',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  viewInsets: const EdgeInsets.only(bottom: 280),
                ),
                child: child!,
              );
            },
            home: Scaffold(
              // Keep insets so fields under dialogs/sheets still clear the keyboard.
              resizeToAvoidBottomInset: false,
              body: AppTextField(controller: controller, label: 'Field'),
            ),
          ),
        );

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.scrollPadding.bottom, AppSpacing.xl + 280);
      },
    );

    testWidgets(
      'uses comfort gap inside resized Scaffold body (viewInsets removed)',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  viewInsets: const EdgeInsets.only(bottom: 280),
                ),
                child: child!,
              );
            },
            home: Scaffold(
              resizeToAvoidBottomInset: true,
              body: AppTextField(controller: controller, label: 'Field'),
            ),
          ),
        );

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.scrollPadding.bottom, AppSpacing.xl);
      },
    );
  });

  group('AppScaffold', () {
    testWidgets('keeps resizeToAvoidBottomInset enabled by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppScaffold(body: SizedBox.shrink())),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.resizeToAvoidBottomInset, isTrue);
    });
  });
}
