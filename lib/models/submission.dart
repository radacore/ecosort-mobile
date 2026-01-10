class Submission {
  final String id;
  final String userId;
  final String wasteTypeId;
  final double volume;
  final double weight;
  final int points;
  final DateTime submittedAt;
  final String? imageUrl;

  Submission({
    required this.id,
    required this.userId,
    required this.wasteTypeId,
    required this.volume,
    required this.weight,
    required this.points,
    required this.submittedAt,
    this.imageUrl,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      wasteTypeId: json['waste_type_id'] as String,
      volume: (json['volume'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      points: json['points'] as int,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'waste_type_id': wasteTypeId,
      'volume': volume,
      'weight': weight,
      'points': points,
      'submitted_at': submittedAt.toIso8601String(),
      'image_url': imageUrl,
    };
  }
}