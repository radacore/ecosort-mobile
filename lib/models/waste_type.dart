class WasteType {
  final String id;
  final String name;
  final double pointsPerKg;

  WasteType({
    required this.id,
    required this.name,
    required this.pointsPerKg,
  });

  factory WasteType.fromJson(Map<String, dynamic> json) {
    return WasteType(
      id: json['id'] as String,
      name: json['name'] as String,
      pointsPerKg: (json['points_per_kg'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points_per_kg': pointsPerKg,
    };
  }

  static List<WasteType> getWasteTypes() {
    return [
      WasteType(id: '1', name: 'Organik', pointsPerKg: 10.0),
      WasteType(id: '2', name: 'Plastik', pointsPerKg: 15.0),
      WasteType(id: '3', name: 'Kertas', pointsPerKg: 12.0),
      WasteType(id: '4', name: 'Logam', pointsPerKg: 20.0),
      WasteType(id: '5', name: 'Kaca', pointsPerKg: 18.0),
    ];
  }
}