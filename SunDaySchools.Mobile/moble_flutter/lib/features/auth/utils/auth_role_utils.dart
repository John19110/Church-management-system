import 'dart:convert';

class AuthRoleUtils {
  static const List<String> _roleClaimKeys = <String>[
    'http://schemas.microsoft.com/ws/2008/06/identity/claims/role',
    'role',
    'roles',
  ];

  static String? extractPrimaryRole(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
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
    if (role == 'admin') return '/admin-home';
    if (role == 'servant') return '/servant-home';
    return '/dashboard';
  }
}
