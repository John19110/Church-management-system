// Conditional export so mobile analysis never sees package:web.
export 'landing_external_links_stub.dart'
    if (dart.library.js_interop) 'landing_external_links_web.dart';
