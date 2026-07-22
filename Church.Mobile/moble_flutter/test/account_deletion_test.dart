import 'package:church_app/core/constants/app_constants.dart';
import 'package:church_app/core/l10n/app_localizations.dart';
import 'package:church_app/features/auth/repositories/auth_repository.dart';
import 'package:church_app/features/auth/widgets/delete_account_section.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _DeleteRequestInterceptor extends Interceptor {
  String? method;
  String? path;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    method = options.method;
    path = options.path;
    handler.resolve(Response<void>(requestOptions: options, statusCode: 204));
  }
}

void main() {
  test(
    'deleteAccount sends authenticated account endpoint DELETE request',
    () async {
      final interceptor = _DeleteRequestInterceptor();
      final dio = Dio()..interceptors.add(interceptor);
      final repository = AuthRepository(dio);

      await repository.deleteAccount();

      expect(interceptor.method, 'DELETE');
      expect(interceptor.path, AppConstants.deleteAccountEndpoint);
    },
  );

  testWidgets('delete account requires a second destructive confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SingleChildScrollView(child: DeleteAccountSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete Account').last);
    await tester.pumpAndSettle();

    expect(find.text('Delete your account?'), findsOneWidget);
    expect(
      find.text(
        'Deleting your account is permanent and cannot be undone. '
        'All personal data associated with your account will be permanently deleted.',
      ),
      findsNWidgets(2),
    );
    expect(find.text('Delete Account'), findsNWidgets(2));
  });
}
