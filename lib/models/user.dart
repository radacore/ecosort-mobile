class User {
  final String id;
  final String name;
  final String email;
  final String? address;
  final String? district;
  final int totalPoints;
  final int streakDays;
  final String? avatarPath;
  final String? lastScanAt;
  final String? role;
  final String? emailVerifiedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.address,
    this.district,
    required this.totalPoints,
    required this.streakDays,
    this.avatarPath,
    this.lastScanAt,
    this.role,
    this.emailVerifiedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle your backend's specific response format
    // Data is nested under 'pengguna' key
    Map<String, dynamic> userData = json;
    if (json.containsKey('pengguna')) {
      userData = json['pengguna'] as Map<String, dynamic>;
    }
    
    // Also handle kecamatan if present
    String? districtName;
    if (userData.containsKey('kecamatan') && userData['kecamatan'] != null) {
      if (userData['kecamatan'] is Map) {
        districtName = (userData['kecamatan'] as Map)['nama'] as String?;
      }
    }
    
    // Handle avatar path
    String? avatarPath;
    if (userData.containsKey('avatar_profil') && userData['avatar_profil'] != null) {
      if (userData['avatar_profil'] is Map) {
        avatarPath = (userData['avatar_profil'] as Map)['path'] as String?;
      }
    }
    
    return User(
      id: userData['id'].toString(),
      name: userData['nama'] as String? ?? '',
      email: userData['email'] as String? ?? '',
      address: userData['alamat'] as String?,
      // Prioritize the kecamatan name over the ID
      district: districtName ?? userData['kecamatan_id']?.toString(),
      totalPoints: userData['points'] as int? ?? 0,
      streakDays: userData['streak_days'] as int? ?? 0,
      avatarPath: avatarPath,
      lastScanAt: userData['last_scan_at'] as String?,
      role: userData['role'] as String?,
      emailVerifiedAt: userData['email_verified_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'address': address,
      'district': district,
      'total_points': totalPoints,
      'streak_days': streakDays,
      'avatar_path': avatarPath,
      'last_scan_at': lastScanAt,
      'role': role,
      'email_verified_at': emailVerifiedAt,
    };
  }
}