class PanduanItem {
  final int id;
  final String judul;
  final String ikon;
  final String deskripsi;
  final List<String> konten;
  final int urutan;

  PanduanItem({
    required this.id,
    required this.judul,
    required this.ikon,
    required this.deskripsi,
    required this.konten,
    required this.urutan,
  });

  factory PanduanItem.fromJson(Map<String, dynamic> json) {
    return PanduanItem(
      id: json['id'] ?? 0,
      judul: json['judul']?.toString() ?? '',
      ikon: json['ikon']?.toString() ?? '📋',
      deskripsi: json['deskripsi']?.toString() ?? '',
      konten: (json['konten'] is List)
          ? List<String>.from((json['konten'] as List).map((e) => e.toString()))
          : [],
      urutan: json['urutan'] ?? 0,
    );
  }
}
