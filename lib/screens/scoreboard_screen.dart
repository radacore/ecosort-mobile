import 'package:flutter/material.dart';
import '../models/scoreboard_entry.dart';
import '../services/scoreboard_service.dart';
import '../services/auth_service.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  final ScoreboardService _scoreboardService = ScoreboardService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _hasError = false;
  ScoreboardResponse? _data;

  @override
  void initState() {
    super.initState();
    _loadScoreboard();
  }

  Future<void> _loadScoreboard() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final token = await _authService.getToken();
    if (!mounted) return;

    if (token == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    final response = await _scoreboardService.fetchScoreboard(token);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response == null) {
        _hasError = true;
      } else {
        _data = response;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1B5E20),
                        Color(0xFF2E7D32),
                        Color(0xFF43A047),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -20,
                        right: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        left: -30,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      // Trophy and title
                      SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 42,
                                  color: Colors.amberAccent,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Papan Skor',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Peringkat pengguna EcoSort',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _loadScoreboard,
          color: const Color(0xFF2E7D32),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                )
              : _hasError
              ? _buildErrorState()
              : _data == null
              ? _buildEmptyState()
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  children: [
                    if (_data!.currentUser != null)
                      _CurrentUserCard(entry: _data!.currentUser!),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.leaderboard_rounded,
                              color: Color(0xFF2E7D32),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Peringkat Tertinggi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ..._data!.topScores.asMap().entries.map(
                      (mapEntry) => _ScoreboardTile(
                        entry: mapEntry.value,
                        index: mapEntry.key,
                        isCurrentUser:
                            _data!.currentUser?.userId == mapEntry.value.userId,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: Colors.red[300],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Gagal memuat papan skor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Periksa koneksi internet dan coba lagi',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadScoreboard,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Belum ada data papan skor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mulai setor sampah untuk masuk peringkat!',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrentUserCard extends StatelessWidget {
  final ScoreboardEntry entry;

  const _CurrentUserCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2.5,
                    ),
                  ),
                  child: _AvatarCircle(entry: entry, size: 56),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Peringkat Anda',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              entry.rank > 0 ? '#${entry.rank}' : '—',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.star_rounded,
                    label: 'Total Poin',
                    value: '${entry.totalPoints}',
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _StatItem(
                    icon: Icons.emoji_events_rounded,
                    label: 'Peringkat',
                    value: entry.rank > 0 ? '#${entry.rank}' : '—',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.amberAccent, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScoreboardTile extends StatelessWidget {
  final ScoreboardEntry entry;
  final int index;
  final bool isCurrentUser;

  const _ScoreboardTile({
    required this.entry,
    required this.index,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTopThree = entry.rank > 0 && entry.rank <= 3;

    final List<Color> medalColors;
    final IconData? medalIcon;
    switch (entry.rank) {
      case 1:
        medalColors = [const Color(0xFFFFD700), const Color(0xFFFFC107)];
        medalIcon = Icons.looks_one_rounded;
        break;
      case 2:
        medalColors = [const Color(0xFFBDBDBD), const Color(0xFF9E9E9E)];
        medalIcon = Icons.looks_two_rounded;
        break;
      case 3:
        medalColors = [const Color(0xFFCD7F32), const Color(0xFFBF6B23)];
        medalIcon = Icons.looks_3_rounded;
        break;
      default:
        medalColors = [const Color(0xFF66BB6A), const Color(0xFF43A047)];
        medalIcon = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(
                color: const Color(0xFF43A047).withOpacity(0.3),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: medalColors),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isTopThree
                    ? [
                        BoxShadow(
                          color: medalColors.first.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: medalIcon != null
                    ? Icon(medalIcon, color: Colors.white, size: 22)
                    : Text(
                        '${entry.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            _AvatarCircle(entry: entry, size: 44),
            const SizedBox(width: 12),
            // Name and points
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isCurrentUser
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF212121),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Points badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isTopThree
                    ? medalColors.first.withOpacity(0.12)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: isTopThree ? medalColors.first : Colors.amber[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.totalPoints}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isTopThree ? medalColors.first : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final ScoreboardEntry entry;
  final double size;

  const _AvatarCircle({required this.entry, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final imageProvider = _resolveImageProvider(entry.avatarUrl);
    final initials = entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE8F5E9),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            )
          : null,
    );
  }

  ImageProvider? _resolveImageProvider(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    return NetworkImage(url);
  }
}
