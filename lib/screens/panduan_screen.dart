import 'package:flutter/material.dart';
import '../models/panduan_model.dart';
import '../services/panduan_service.dart';

class PanduanScreen extends StatefulWidget {
  const PanduanScreen({super.key});

  @override
  State<PanduanScreen> createState() => _PanduanScreenState();
}

class _PanduanScreenState extends State<PanduanScreen> {
  final PanduanService _panduanService = PanduanService();
  bool _isLoading = false;
  String? _errorMessage;
  List<PanduanItem> _panduanItems = [];

  @override
  void initState() {
    super.initState();
    _loadPanduan();
  }

  Future<void> _loadPanduan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final items = await _panduanService.fetchPanduan();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _panduanItems = items;
      if (items.isEmpty) {
        _errorMessage = 'Belum ada panduan tersedia.';
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
                        bottom: 30,
                        left: -40,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      // Book icon and title
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
                                  Icons.menu_book_rounded,
                                  size: 42,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Panduan',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cara memilah sampah dengan benar',
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
          onRefresh: _loadPanduan,
          color: const Color(0xFF2E7D32),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                )
              : _errorMessage != null && _panduanItems.isEmpty
              ? _buildErrorState()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic panduan items from backend
                      if (_panduanItems.isNotEmpty) ...[
                        _buildSectionHeader(
                          Icons.category_rounded,
                          'Kategori Sampah',
                        ),
                        const SizedBox(height: 14),
                        ..._panduanItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildPanduanCard(item),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Tips section
                      _buildSectionHeader(
                        Icons.tips_and_updates_rounded,
                        'Tips Pemilahan yang Benar',
                      ),
                      const SizedBox(height: 14),

                      // DO card
                      _buildTipsCard(
                        icon: Icons.check_circle_rounded,
                        title: 'Yang Harus Dilakukan',
                        color: const Color(0xFF43A047),
                        tips: [
                          'Cuci bersih kemasan plastik/kaleng',
                          'Keringkan sampah sebelum disetor',
                          'Pisahkan berdasarkan kategori jelas',
                          'Gunakan wadah terpisah untuk setiap jenis',
                          'Periksa label kemasan untuk panduan',
                        ],
                      ),
                      const SizedBox(height: 12),

                      // DON'T card
                      _buildTipsCard(
                        icon: Icons.cancel_rounded,
                        title: 'Yang Tidak Boleh Dilakukan',
                        color: Colors.red[600]!,
                        tips: [
                          'Jangan campur sampah basah dan kering',
                          'Jangan biarkan sampah menumpuk terlalu lama',
                          'Jangan masukkan sampah B3 ke tempat sampah biasa',
                          'Jangan remas kertas yang masih bisa digunakan',
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Benefits section
                      _buildSectionHeader(
                        Icons.eco_rounded,
                        'Manfaat Pemilahan yang Benar',
                      ),
                      const SizedBox(height: 14),

                      // Environment benefits
                      _buildBenefitCard(
                        icon: Icons.park_rounded,
                        title: 'Bagi Lingkungan',
                        gradientColors: [
                          const Color(0xFF43A047),
                          const Color(0xFF66BB6A),
                        ],
                        benefits: [
                          'Mengurangi polusi tanah dan air',
                          'Menghemat sumber daya alam',
                          'Mengurangi emisi gas rumah kaca',
                        ],
                      ),
                      const SizedBox(height: 12),

                      // User benefits
                      _buildBenefitCard(
                        icon: Icons.star_rounded,
                        title: 'Bagi Pengguna EcoSort',
                        gradientColors: [
                          const Color(0xFFFFA726),
                          const Color(0xFFFFB74D),
                        ],
                        benefits: [
                          'Mendapatkan lebih banyak points',
                          'Streak days bertambah',
                          'Kontribusi langsung untuk lingkungan',
                          'Efisiensi proses daur ulang',
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
        ],
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
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPanduan,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Muat Ulang'),
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

  Widget _buildPanduanCard(PanduanItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(item.ikon, style: const TextStyle(fontSize: 24)),
          ),
          title: Text(
            item.judul,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item.deskripsi,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [
            if (item.konten.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...item.konten.map(
                    (content) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF43A047),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              content,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF424242),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<String> tips,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Tips list
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Column(
              children: tips.map((tip) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF424242),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required List<Color> gradientColors,
    required List<String> benefits,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white.withOpacity(0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        benefit,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
