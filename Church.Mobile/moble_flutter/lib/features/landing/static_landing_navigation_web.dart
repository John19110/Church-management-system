import 'package:web/web.dart' as web;

/// Full-page navigation to the static HTML marketing site.
void goToStaticLandingHome() {
  web.window.location.assign('/landing/index.html');
}
