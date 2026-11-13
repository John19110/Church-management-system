class OptionalModuleDto {
  final String id;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final String icon;
  final bool isEnabled;

  const OptionalModuleDto({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.icon,
    required this.isEnabled,
  });

  factory OptionalModuleDto.fromJson(Map<String, dynamic> json) {
    return OptionalModuleDto(
      id: json['id'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? '',
      descriptionAr: json['descriptionAr'] as String? ?? '',
      icon: json['icon'] as String? ?? 'extension',
      isEnabled: json['isEnabled'] as bool? ?? false,
    );
  }

  String displayName(bool isArabic) =>
      isArabic && nameAr.trim().isNotEmpty ? nameAr : nameEn;

  String displayDescription(bool isArabic) =>
      isArabic && descriptionAr.trim().isNotEmpty
          ? descriptionAr
          : descriptionEn;
}

class StockItemDto {
  final int id;
  final String name;
  final String? nameAr;
  final String? description;
  final String? descriptionAr;
  final int amount;
  final String? imageUrl;
  final DateTime? createdAtUtc;
  final DateTime? updatedAtUtc;

  const StockItemDto({
    required this.id,
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    required this.amount,
    this.imageUrl,
    this.createdAtUtc,
    this.updatedAtUtc,
  });

  factory StockItemDto.fromJson(Map<String, dynamic> json) {
    return StockItemDto(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['descriptionAr'] as String?,
      amount: json['amount'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
      createdAtUtc: DateTime.tryParse(json['createdAtUtc'] as String? ?? ''),
      updatedAtUtc: DateTime.tryParse(json['updatedAtUtc'] as String? ?? ''),
    );
  }

  StockItemDto copyWith({int? amount, String? imageUrl}) {
    return StockItemDto(
      id: id,
      name: name,
      nameAr: nameAr,
      description: description,
      descriptionAr: descriptionAr,
      amount: amount ?? this.amount,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc,
    );
  }

  String displayName(bool isArabic) {
    if (isArabic && (nameAr?.trim().isNotEmpty ?? false)) return nameAr!;
    return name;
  }

  String? displayDescription(bool isArabic) {
    if (isArabic && (descriptionAr?.trim().isNotEmpty ?? false)) {
      return descriptionAr;
    }
    return description;
  }
}

class StockAmountChangeResult {
  final int id;
  final int amount;

  const StockAmountChangeResult({required this.id, required this.amount});

  factory StockAmountChangeResult.fromJson(Map<String, dynamic> json) {
    return StockAmountChangeResult(
      id: json['id'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
    );
  }
}

/// Stable module ids matching backend [PredefinedModules].
class OptionalModuleIds {
  static const stock = 'stock';
}
