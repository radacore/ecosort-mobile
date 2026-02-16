class NewsArticle {
  final String title;
  final String slug;
  final String category;
  final String content;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NewsArticle({
    required this.title,
    required this.slug,
    required this.category,
    required this.content,
    required this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['judul']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      category: json['kategori']?.toString() ?? '',
      content: json['konten']?.toString() ?? '',
      imageUrl: json['foto_url']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}
