class SelectOption {
  final int id;
  final String name;

  const SelectOption({required this.id, required this.name});

  factory SelectOption.fromJson(Map<String, dynamic> json) {
    return SelectOption(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?)?.trim() ?? '',
    );
  }
}

