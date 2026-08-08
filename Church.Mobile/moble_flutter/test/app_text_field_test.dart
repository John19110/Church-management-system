import 'package:church_app/shared/widgets/app_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  testWidgets(
    'multiline AppTextField upgrades keyboardType when action is newline',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(
          AppTextField(
            controller: controller,
            label: 'Notes',
            maxLines: 3,
            textInputAction: TextInputAction.newline,
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.multiline);
      expect(field.textInputAction, TextInputAction.newline);
      expect(field.maxLines, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'multiline AppTextField auto-resolves newline + multiline keyboard',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(AppTextField(controller: controller, label: 'JSON', maxLines: 5)),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.multiline);
      expect(field.textInputAction, TextInputAction.newline);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'single-line AppTextField keeps TextInputType.text and next action',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(AppTextField(controller: controller, label: 'Name')),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.text);
      expect(field.textInputAction, TextInputAction.next);
      expect(field.maxLines, 1);
    },
  );

  testWidgets('multiline AppTextField preserves non-text keyboard types', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(
        AppTextField(
          controller: controller,
          label: 'Address',
          maxLines: 3,
          keyboardType: TextInputType.streetAddress,
          textInputAction: TextInputAction.newline,
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.streetAddress);
    expect(field.textInputAction, TextInputAction.newline);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiline AppTextField with done keeps TextInputType.text', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(
        AppTextField(
          controller: controller,
          label: 'Reason',
          maxLines: 2,
          textInputAction: TextInputAction.done,
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.text);
    expect(field.textInputAction, TextInputAction.done);
    expect(tester.takeException(), isNull);
  });
}
