class SelectOption {
  final int id;
  final String name;

  const SelectOption({required this.id, required this.name});

  factory SelectOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['Id'];
    final id = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final rawName = json['name'] ?? json['Name'];
    return SelectOption(
      id: id,
      name: rawName?.toString().trim() ?? '',
    );
  }
}

