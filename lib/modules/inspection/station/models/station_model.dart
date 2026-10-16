class StationItem {
  final int id;
  final String name;
  final String code;
  final int? divisionId;

  StationItem({
    required this.id,
    required this.name,
    required this.code,
    this.divisionId,
  });

  String get displayLabel => code.isNotEmpty ? '$name ($code)' : name;

  factory StationItem.fromJson(Map<String, dynamic> json) {
    return StationItem(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name:
          (json['name'] ?? json['station_name'] ?? json['station'] ?? 'Unknown')
              .toString()
              .trim(),
      code: (json['station_code'] ?? json['code'] ?? '').toString().trim(),
      divisionId: json['division_id'] is int
          ? json['division_id']
          : int.tryParse(json['division_id']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'station_code': code,
      'division_id': divisionId,
    };
  }
}
