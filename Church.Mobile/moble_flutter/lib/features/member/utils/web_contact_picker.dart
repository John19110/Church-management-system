// Web Contact Picker API helpers.
//
// Native / VM (`dart.library.io`) always get the stub. Web builds (no `dart:io`)
// get the browser implementation via `dart.library.js_interop`.
export 'web_contact_picker_stub.dart'
    if (dart.library.io) 'web_contact_picker_stub.dart'
    if (dart.library.js_interop) 'web_contact_picker_web.dart';
