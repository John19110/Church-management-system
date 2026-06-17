// PendingUserDto is reused for pending admins.
export '../../admin/models/admin_models.dart' show PendingUserDto;
export '../../meeting/models/meeting_models.dart' show MeetingAddDto;

/// A church user awaiting Super Admin approval (any role), with full card data.
class PendingChurchUserDto {
  final String id;
  final String name;
  final String phoneNumber;
  final String role;

  /// Requested role chosen at registration: Servant / MeetingAdmin / ChurchAdmin.
  final String? requestedRole;
  final String? requestedMeetingName;

  /// Meeting Admin phone provided by a servant at registration (routing hint).
  final String? meetingAdminPhoneNumber;
  final int? requestedChurchId;
  final String? requestedChurchPublicId;
  final String? imageUrl;
  final String? imageFileName;
  final DateTime? createdAt;

  const PendingChurchUserDto({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.role,
    this.requestedRole,
    this.requestedMeetingName,
    this.meetingAdminPhoneNumber,
    this.requestedChurchId,
    this.requestedChurchPublicId,
    this.imageUrl,
    this.imageFileName,
    this.createdAt,
  });

  /// Servant / Meeting Admin must be assigned to a meeting on approval.
  bool get requiresMeeting {
    final rr = requestedRole?.toLowerCase();
    if (rr == 'servant' || rr == 'meetingadmin') return true;
    if (rr == 'churchadmin') return false;
    final r = role.toLowerCase();
    return r == 'servant' || r == 'admin';
  }

  /// Best image reference for the avatar (falls back to file name).
  String? get displayImageUrl {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    final file = imageFileName?.trim();
    if (file == null || file.isEmpty) return null;
    if (file.contains('://') || file.startsWith('/')) return file;
    return '/images/$file';
  }

  factory PendingChurchUserDto.fromJson(Map<String, dynamic> json) {
    return PendingChurchUserDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      role: json['role'] as String? ?? '',
      requestedRole: json['requestedRole'] as String?,
      requestedMeetingName: json['requestedMeetingName'] as String?,
      meetingAdminPhoneNumber: json['meetingAdminPhoneNumber'] as String?,
      requestedChurchId: (json['requestedChurchId'] as num?)?.toInt(),
      requestedChurchPublicId: json['requestedChurchPublicId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      imageFileName: json['imageFileName'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}
