import '../../super_admin/models/super_admin_models.dart';

enum PendingRequestSource { registration, legacyAdmin, legacyServant }

class PendingRequest {
  final String id;
  final String name;
  final String phoneNumber;
  final String roleKey;
  final DateTime? requestedAt;
  final PendingRequestSource source;
  final PendingChurchUserDto? churchUser;
  final PendingUserDto? legacyUser;

  const PendingRequest({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.roleKey,
    required this.source,
    this.requestedAt,
    this.churchUser,
    this.legacyUser,
  });

  factory PendingRequest.fromChurchUser(PendingChurchUserDto user) {
    return PendingRequest(
      id: user.id,
      name: user.name,
      phoneNumber: user.phoneNumber,
      roleKey: user.requestedRole ?? user.role,
      requestedAt: user.createdAt,
      source: PendingRequestSource.registration,
      churchUser: user,
    );
  }

  factory PendingRequest.legacyAdmin(PendingUserDto user) {
    return PendingRequest(
      id: user.id,
      name: user.name,
      phoneNumber: user.phoneNumber,
      roleKey: 'MeetingAdmin',
      source: PendingRequestSource.legacyAdmin,
      legacyUser: user,
    );
  }

  factory PendingRequest.legacyServant(PendingUserDto user) {
    return PendingRequest(
      id: user.id,
      name: user.name,
      phoneNumber: user.phoneNumber,
      roleKey: 'Servant',
      source: PendingRequestSource.legacyServant,
      legacyUser: user,
    );
  }

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}

List<PendingRequest> mergePendingRequests({
  List<PendingChurchUserDto> registrations = const [],
  List<PendingUserDto> legacyAdmins = const [],
  List<PendingUserDto> legacyServants = const [],
}) {
  final seen = <String>{};
  final merged = <PendingRequest>[];

  for (final user in registrations) {
    if (user.id.isEmpty || seen.contains(user.id)) continue;
    seen.add(user.id);
    merged.add(PendingRequest.fromChurchUser(user));
  }
  for (final user in legacyAdmins) {
    if (user.id.isEmpty || seen.contains(user.id)) continue;
    seen.add(user.id);
    merged.add(PendingRequest.legacyAdmin(user));
  }
  for (final user in legacyServants) {
    if (user.id.isEmpty || seen.contains(user.id)) continue;
    seen.add(user.id);
    merged.add(PendingRequest.legacyServant(user));
  }

  merged.sort((a, b) {
    final aDate = a.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });
  return merged;
}
