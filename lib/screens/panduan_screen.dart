import 'package:flutter/material.dart';

class PanduanScreen extends StatelessWidget {
  const PanduanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan'),
        backgroundColor: const Color(0xFF368b3a),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
            const Text(
              '📋 Kategori Sampah',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // SAMPAH ORGANIK
            _buildCategoryCard(
              icon: '🍃',
              title: 'SAMPAH ORGANIK',
              description: 'Sampah yang dapat terurai secara alami oleh mikroorganisme',
              examples: [
                'Sisa makanan (nasi, sayuran, buah-busuk)',
                'Daun kering dan ranting',
                'Kulit buah dan kulit sayuran',
                'Bunga layu dan tanaman',
                'Sisa teh dan kopi',
                'Produk kayu alami',
              ],
              tips: [
                'Keringkan terlebih dahulu sebelum disetor',
                'Pisahkan dari sampah basah lainnya',
                'Gunakan wadah kedap udara untuk menghindari bau',
              ],
            ),
            
            const SizedBox(height: 20),
            
            // SAMPAH ANORGANIK
            _buildCategoryCard(
              icon: '🫙',
              title: 'SAMPAH ANORGANIK',
              description: 'Sampah yang tidak dapat terurai secara alami',
              examples: [],
              tips: [
                'Cuci bersih sebelum disetor',
                'Keringkan terlebih dahulu',
                'Pisahkan berdasarkan jenis material',
                'Ratakan kardus untuk menghemat space',
              ],
              children: [
                const SizedBox(height: 15),
                const Text(
                  'Sub-kategori:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                
                // PLASTIK
                _buildSubCategory(
                  title: 'A. PLASTIK',
                  items: [
                    'Botol plastik (minuman, deterjen)',
                    'Kantong plastik dan kemasan',
                    'Mainan plastik rusak',
                    'Perabot plastik bekas',
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // KERTAS
                _buildSubCategory(
                  title: 'B. KERTAS',
                  items: [
                    'Koran dan majalah bekas',
                    'Kardus dan karton',
                    'Kertas HVS bekas',
                    'Buku tidak terpakai',
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // KALENG
                _buildSubCategory(
                  title: 'C. KALENG',
                  items: [
                    'Kaleng minuman',
                    'Kaleng makanan',
                    'Kemasan aerosol',
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // KACA
                _buildSubCategory(
                  title: 'D. KACA',
                  items: [
                    'Botol kaca (minuman, kecap)',
                    'Gelas dan piring kaca pecah',
                    'Jendela kaca',
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // SAMPAH RESIDU
            _buildCategoryCard(
              icon: '🗑️',
              title: 'SAMPAH RESIDU',
              description: 'Sampah yang tidak dapat dipilah lebih lanjut dan tidak bisa didaur ulang atau diolah',
              examples: [
                'Popok bekas',
                'Tisu toilet dan tisu basah',
                'Kapas dan pembalut',
                'Spons dan serbet kotor',
                'Sisa permen karet',
                'Abu sisa pembakaran',
                'Kaca pecah yang tidak bisa didaur ulang',
                'Keramik dan porselen pecah',
                'Karet yang tidak bisa didaur ulang',
                'Bahan-bahan komposit yang sulit dipisahkan',
              ],
              tips: [
                'Jangan dicampur dengan jenis sampah lain',
                'Bungkus dengan plastik sebelum dibuang',
                'Jangan disimpan terlalu lama di rumah',
                'Pastikan benar-benar tidak bisa didaur ulang sebelum dimasukkan ke residu',
              ],
            ),
            
            const SizedBox(height: 20),
            
            // SAMPAH B3
            _buildCategoryCard(
              icon: '⚠️',
              title: 'SAMPAH B3 (BAHAN BERBAHAYA & BERACUN)',
              description: 'Sampah yang mengandung bahan berbahaya bagi kesehatan dan lingkungan',
              examples: [
                'Baterai bekas',
                'Lampu neon dan LED',
                'Elektronik rusak (HP, laptop)',
                'Obat-obatan kadaluarsa',
                'Kimia rumah tangga (pembersih, pestisida)',
              ],
              tips: [
                '❌ JANGAN dicampur dengan sampah biasa',
                '❌ JANGAN dibakar sembarangan',
                '❌ JANGAN dibuang ke saluran air',
              ],
            ),
            
            const SizedBox(height: 30),
            
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
    );
  }
  
  Widget _buildCategoryCard({
    required String icon,
    required String title,
    required String description,
    required List<String> examples,
    required List<String> tips,
    List<Widget> children = const [],
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
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
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (examples.isNotEmpty) ...[
              const SizedBox(height: 15),
              const Text(
                'Contoh Items:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: examples.map((example) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text('• $example'),
                  )
                ).toList(),
              ),
            ],
            if (tips.isNotEmpty) ...[
              const SizedBox(height: 15),
              const Text(
                'Tips Pemilahan:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tips.map((tip) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text('• $tip'),
                  )
                ).toList(),
              ),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubCategory({
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 10),
              child: Text('• $item'),
            )
          ).toList(),
        ),
      ],
    );
  }
}