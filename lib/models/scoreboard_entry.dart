class ScoreboardEntry {
  final int userId;
  final String name;
  final int? avatarId;
  final String? avatarUrl;
  final int totalPoints;
  final int rank;

  ScoreboardEntry({
    required this.userId,
    required this.name,
    required this.avatarId,
    required this.avatarUrl,
    required this.totalPoints,
    required this.rank,
  });

  factory ScoreboardEntry.fromJson(Map<String, dynamic> json) {
    return ScoreboardEntry(
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      name: json['nama']?.toString() ?? '',
      avatarId: json['avatar_profil_id'] is int
          ? json['avatar_profil_id'] as int
          : int.tryParse(json['avatar_profil_id']?.toString() ?? ''),
      avatarUrl: json['avatar_url']?.toString(),
      totalPoints: json['total_poin'] is int
          ? json['total_poin'] as int
          : json['total_validasi'] is int
              ? json['total_validasi'] as int
              : int.tryParse(json['total_poin']?.toString() ?? json['total_validasi']?.toString() ?? '') ?? 0,
      rank: json['rank'] is int
          ? json['rank'] as int
          : int.tryParse(json['rank']?.toString() ?? '') ?? 0,
    );
  }
}
