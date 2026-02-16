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
      appBar: AppBar(
        title: const Text('Panduan'),
        backgroundColor: const Color(0xFF368b3a),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPanduan,
        color: const Color(0xFF368b3a),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _panduanItems.isEmpty
            ? _buildErrorState()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Panduan Pemilahan Sampah',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF368b3a),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dynamic panduan items from backend
                    if (_panduanItems.isNotEmpty) ...[
                      const Text(
                        '📋 Kategori Sampah',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._panduanItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPanduanCard(item),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Static tips section
                    const Text(
                      '♻️ Tips Pemilahan yang Benar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      '✅ DO (Yang Harus Dilakukan):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      '• Cuci bersih kemasan plastik/kaleng\n'
                      '• Keringkan sampah sebelum disetor\n'
                      '• Pisahkan berdasarkan kategori jelas\n'
                      '• Gunakan wadah terpisah untuk setiap jenis\n'
                      '• Periksa label kemasan untuk panduan',
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      '❌ DON\'T (Yang Tidak Boleh Dilakukan):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      '• Jangan campur sampah basah dan kering\n'
                      '• Jangan biarkan sampah menumpuk terlalu lama\n'
                      '• Jangan masukkan sampah B3 ke tempat sampah biasa\n'
                      '• Jangan remas kertas yang masih bisa digunakan',
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      '📊 Manfaat Pemilahan yang Benar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      '🌱 Bagi Lingkungan:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      '• Mengurangi polusi tanah dan air\n'
                      '• Menghemat sumber daya alam\n'
                      '• Mengurangi emisi gas rumah kaca',
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      '💰 Bagi Pengguna EcoSort:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      '• Mendapatkan lebih banyak points\n'
                      '• Streak days bertambah\n'
                      '• Kontribusi langsung untuk lingkungan\n'
                      '• Efisiensi proses daur ulang',
                    ),

                    const SizedBox(height: 30),
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
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadPanduan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF368b3a),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Muat Ulang'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPanduanCard(PanduanItem item) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(item.ikon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.judul,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.deskripsi,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (item.konten.isNotEmpty) ...[
              const SizedBox(height: 15),
              const Text(
                'Detail:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.konten
                    .map(
                      (content) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text('• $content'),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
