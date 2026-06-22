import 'dart:convert';

class AuthRoleUtils {
  static const List<String> _roleClaimKeys = <String>[
    'http://schemas.microsoft.com/ws/2008/06/identity/claims/role',
    'role',
    'roles',
  ];

  static int? extractChurchId(String token) {
    final claims = _decodeClaims(token);
    if (claims == null) return null;
    const keys = ['ChurchId', 'churchId', 'churchid'];
    for (final key in keys) {
      final raw = claims[key];
      if (raw is int && raw > 0) return raw;
      if (raw is String) {
        final parsed = int.tryParse(raw);
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _decodeClaims(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static String? extractPrimaryRole(String token) {
    final claims = _decodeClaims(token);
    if (claims == null) return null;
    try {
      for (final key in _roleClaimKeys) {
        final roleClaim = claims[key];
        if (roleClaim is String && roleClaim.trim().isNotEmpty) {
          return roleClaim.trim().toLowerCase();
        }
        if (roleClaim is List && roleClaim.isNotEmpty) {
          return roleClaim.first.toString().trim().toLowerCase();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String routeForRole(String? role) {
    if (role == 'superadmin') return '/super-admin-home';
    // Default "home" for admin + servant is Classrooms.
    if (role == 'admin') return '/classrooms-home';
    if (role == 'servant') return '/classrooms-home';
    return '/dashboard';
  }

  /// Admin and SuperAdmin can define custom field attributes per entity.
  static bool canManageCustomFields(String? role) =>
      role == 'admin' || role == 'superadmin';

  static bool canDeleteMeeting(String? role) => role == 'superadmin';

  /// Super Admin can edit any church meeting; Meeting Admin only their own meeting.
  static bool canEditMeeting(String? role) =>
      role == 'admin' || role == 'superadmin';

  static bool canDeleteClassroom(String? role) =>
      role == 'admin' || role == 'superadmin';
}
