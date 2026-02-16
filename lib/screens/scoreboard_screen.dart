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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Papan Skor'),
        backgroundColor: const Color(0xFF368b3a),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadScoreboard,
        color: const Color(0xFF368b3a),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
            ? _buildErrorState()
            : _data == null
            ? _buildEmptyState()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_data!.currentUser != null)
                    _CurrentUserCard(entry: _data!.currentUser!),
                  const SizedBox(height: 24),
                  Text(
                    'Peringkat Tertinggi',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2A1C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._data!.topScores.map(
                    (entry) => _ScoreboardTile(
                      entry: entry,
                      isCurrentUser: _data!.currentUser?.userId == entry.userId,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat papan skor.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadScoreboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF368b3a),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
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
      children: const [
        SizedBox(height: 80),
        Icon(Icons.emoji_events, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Belum ada data papan skor.',
            style: TextStyle(color: Colors.grey),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AvatarCircle(entry: entry, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total poin: ${entry.totalPoints}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (entry.rank > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF368b3a),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '#${entry.rank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Belum Ada',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x11368b3a),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Tetap konsisten melakukan setoran untuk mempertahankan peringkat Anda!',
                style: TextStyle(fontSize: 13, color: Color(0xFF35613A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreboardTile extends StatelessWidget {
  final ScoreboardEntry entry;
  final bool isCurrentUser;

  const _ScoreboardTile({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final Color badgeColor;
    switch (entry.rank) {
      case 1:
        badgeColor = const Color(0xFFFFD700);
        break;
      case 2:
        badgeColor = const Color(0xFFC0C0C0);
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32);
        break;
      default:
        badgeColor = const Color(0xFF368b3a);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0x14368b3a) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            _AvatarCircle(entry: entry, size: 48),
            if (entry.rank > 0)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    '#${entry.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Total poin: ${entry.totalPoints}'),
        trailing: Icon(
          isCurrentUser ? Icons.star : Icons.arrow_forward_ios,
          color: isCurrentUser ? const Color(0xFF368b3a) : Colors.grey,
          size: isCurrentUser ? 22 : 16,
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
      backgroundColor: const Color(0x19368b3a),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF368b3a),
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
