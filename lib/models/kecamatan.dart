class Kecamatan {
  final String id;
  final String name;

  Kecamatan({
    required this.id,
    required this.name,
  });

  factory Kecamatan.fromJson(Map<String, dynamic> json) {
    return Kecamatan(
      id: json['id'].toString(),
      name: json['nama'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': name,
    };
  }

  @override
  String toString() => name;
}