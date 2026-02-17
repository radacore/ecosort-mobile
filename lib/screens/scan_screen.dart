import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';
import '../services/deposit_service.dart';
import '../utils/constants.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _selectedTrashType;
  bool _isLoading = false;
  bool _isProcessing = false;

  // Hasil dari API
  double? _volumeLiters;
  double? _weightKg;
  File? _imageFile;

  // Daftar jenis sampah
  final List<String> _trashTypes = ['Organik', 'Anorganik'];

  @override
  void initState() {
    super.initState();
    _selectedTrashType = _trashTypes[0]; // Default ke Sampah Organik
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red[400],
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Error', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message, VoidCallback? onOk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF43A047),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Berhasil', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onOk != null) onOk();
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _imageFile = File(pickedFile.path);
        });
        print('Gallery image selected: ${pickedFile.path}');
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorDialog('Gagal memilih atau mengambil gambar');
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? capturedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );

      if (capturedFile != null) {
        setState(() {
          _selectedImage = capturedFile;
          _imageFile = File(capturedFile.path);
        });
        print('Camera image captured: ${capturedFile.path}');
      }
    } catch (e) {
      print('Error taking picture: $e');
      _showErrorDialog('Gagal mengambil gambar dari kamera');
    }
  }

  Future<void> _processImage() async {
    print('=== Starting _processImage ===');
    print('Image file path: ${_imageFile?.path}');
    print('Image file exists: ${_imageFile?.existsSync()}');
    print(
      'Image file length: ${_imageFile != null ? File(_imageFile!.path).lengthSync() : 'null'} bytes',
    );

    if (_imageFile == null) {
      _showErrorDialog('Silakan pilih gambar terlebih dahulu');
      print('Image file is null');
      return;
    }

    if (!await _imageFile!.exists()) {
      _showErrorDialog(
        'File gambar tidak ditemukan. Silakan pilih gambar kembali.',
      );
      print('Image file does not exist at path: ${_imageFile!.path}');
      return;
    }

    int fileSize = await _imageFile!.length();
    print('Image file size: $fileSize bytes');
    if (fileSize == 0) {
      _showErrorDialog('File gambar kosong. Silakan pilih gambar kembali.');
      print('Image file is empty');
      return;
    }

    if (_selectedTrashType == null) {
      _showErrorDialog('Silakan pilih jenis sampah');
      print('Selected trash type is null');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://43.163.127.239:5000/detect-volume'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _imageFile!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      String trashTypeValueForDetection = _getTrashTypeValueForDetection(
        _selectedTrashType!,
      );
      request.fields['trash_type'] = trashTypeValueForDetection;

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('API Response: $responseBody');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (responseBody.startsWith('<')) {
          print(
            'Received HTML response instead of JSON: ${responseBody.substring(0, 100)}...',
          );
          _showErrorDialog(
            'Server mengembalikan error. Silakan coba lagi nanti.',
          );
          return;
        }

        final result = jsonDecode(responseBody);
        print('Volume detection result: $result');

        setState(() {
          _volumeLiters = (result['volume_liters'] as num?)?.toDouble();
          _weightKg = (result['weight_kg'] as num?)?.toDouble();
        });

        if (_volumeLiters == 0.0 || _weightKg == 0.0) {
          _showErrorDialog(
            'Tidak dapat mendeteksi volume atau berat dari gambar. Silakan coba dengan gambar yang berbeda.',
          );
        }
      } else {
        _showErrorDialog(
          'Gagal memproses gambar. Kode error: ${response.statusCode}',
        );
        print('Error response: $responseBody');
      }
    } catch (e) {
      print('Error processing image: $e');
      _showErrorDialog('Terjadi kesalahan saat memproses gambar: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
      print('=== End _processImage ===');
    }
  }

  Future<void> _submitDeposit() async {
    print('=== Starting _submitDeposit ===');
    print('Image file path: ${_imageFile?.path}');

    if (_volumeLiters == null || _weightKg == null) {
      _showErrorDialog(
        'Silakan proses gambar terlebih dahulu untuk mendapatkan volume dan berat',
      );
      print('Volume or weight is null');
      return;
    }

    if (_imageFile == null) {
      _showErrorDialog('Silakan pilih gambar terlebih dahulu');
      print('Image file is null');
      return;
    }

    if (!await _imageFile!.exists()) {
      _showErrorDialog(
        'File gambar tidak ditemukan. Silakan pilih gambar kembali.',
      );
      print('Image file does not exist at path: ${_imageFile!.path}');
      return;
    }

    int fileSize = await _imageFile!.length();
    print('Image file size: $fileSize bytes');
    if (fileSize == 0) {
      _showErrorDialog('File gambar kosong. Silakan pilih gambar kembali.');
      print('Image file is empty');
      return;
    }

    if (_selectedTrashType == null) {
      _showErrorDialog('Silakan pilih jenis sampah');
      print('Trash type is null');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        _showErrorDialog('Sesi tidak valid, silakan login kembali');
        print('Token is null');
        return;
      }

      final depositService = DepositService();
      final userInfo = await depositService.getUserInfo(token);

      if (userInfo == null) {
        _showErrorDialog('Gagal mendapatkan informasi pengguna');
        print('User info is null');
        return;
      }

      String penggunaId = userInfo['id'].toString();
      String kecamatanId = userInfo['kecamatan_id']?.toString() ?? '';

      String detectedType = _getTrashTypeValue(_selectedTrashType!);
      print(
        'Submitting deposit with params: jenisTerdeteksi=$detectedType, volume=${_volumeLiters!}, berat=${_weightKg!}, penggunaId=$penggunaId, kecamatanId=$kecamatanId',
      );

      final result = await depositService.submitDeposit(
        token: token,
        imagePath: _imageFile!.path,
        jenisTerdeteksi: detectedType,
        volumeTerdeteksi: _volumeLiters!,
        beratKg: _weightKg!,
        penggunaId: penggunaId,
        kecamatanId: kecamatanId,
      );

      print('Deposit submission result: $result');

      if (result['success'] == true) {
        _showSuccessDialog('Data berhasil disimpan!', () {
          setState(() {
            _selectedImage = null;
            _imageFile = null;
            _selectedTrashType = _trashTypes[0];
            _volumeLiters = null;
            _weightKg = null;
          });
        });
      } else {
        _showErrorDialog(result['message'] ?? 'Gagal menyimpan data');
      }
    } catch (e) {
      print('Error submitting deposit: $e');
      _showErrorDialog('Terjadi kesalahan saat menyimpan data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('=== End _submitDeposit ===');
    }
  }

  String _getTrashTypeValue(String displayName) {
    switch (displayName) {
      case 'Organik':
        return 'Organik';
      case 'Anorganik':
        return 'Anorganik';
      default:
        return 'Organik';
    }
  }

  String _getTrashTypeValueForDetection(String displayName) {
    switch (displayName) {
      case 'Organik':
        return 'organik';
      case 'Anorganik':
        return 'anorganik';
      default:
        return 'organik';
    }
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
                                  Icons.document_scanner_rounded,
                                  size: 42,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Scan Setor Sampah',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Upload foto sampah untuk deteksi volume',
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
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === UPLOAD SECTION ===

              // Image area
              GestureDetector(
                onTap: _pickImageFromGallery,
                child: Container(
                  width: double.infinity,
                  height: _selectedImage != null ? 220 : 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedImage != null
                          ? const Color(0xFF43A047).withOpacity(0.3)
                          : Colors.grey[300]!,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(_selectedImage!.path),
                                fit: BoxFit.cover,
                              ),
                              // Change button overlay
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.swap_horiz_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ganti',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2E7D32,
                                ).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.cloud_upload_rounded,
                                size: 36,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Ketuk untuk memilih gambar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'dari galeri atau gunakan kamera',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Camera button (full width)
              _buildActionButton(
                icon: Icons.camera_alt_rounded,
                label: 'Ambil dari Kamera',
                onTap: _takePicture,
                isPrimary: true,
              ),
              const SizedBox(height: 24),

              // === TRASH TYPE SECTION ===
              _buildSectionHeader(Icons.delete_sweep_rounded, 'Jenis Sampah'),
              const SizedBox(height: 14),

              // Trash type selection as chips
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: _trashTypes.map((type) {
                    final isSelected = _selectedTrashType == type;
                    final isOrganik = type == 'Organik';
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTrashType = type;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isOrganik
                                      ? const Color(0xFF43A047)
                                      : const Color(0xFF1E88E5))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color:
                                          (isOrganik
                                                  ? const Color(0xFF43A047)
                                                  : const Color(0xFF1E88E5))
                                              .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isOrganik
                                    ? Icons.eco_rounded
                                    : Icons.recycling_rounded,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[500],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                type,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // === PROCESS BUTTON ===
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isProcessing || _imageFile == null)
                      ? null
                      : _processImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 2,
                    shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Memproses gambar...',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Deteksi Volume',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // === RESULT SECTION ===
              if (_volumeLiters != null || _weightKg != null) ...[
                _buildSectionHeader(
                  Icons.analytics_rounded,
                  'Hasil Pemrosesan',
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF43A047),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Deteksi berhasil',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Results
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (_volumeLiters != null)
                              Expanded(
                                child: _buildResultCard(
                                  icon: Icons.straighten_rounded,
                                  label: 'Volume',
                                  value: '${_volumeLiters!.toStringAsFixed(2)}',
                                  unit: 'Liter',
                                  color: const Color(0xFF43A047),
                                ),
                              ),
                            if (_volumeLiters != null && _weightKg != null)
                              const SizedBox(width: 12),
                            if (_weightKg != null)
                              Expanded(
                                child: _buildResultCard(
                                  icon: Icons.fitness_center_rounded,
                                  label: 'Berat',
                                  value: '${_weightKg!.toStringAsFixed(2)}',
                                  unit: 'Kg',
                                  color: const Color(0xFF1E88E5),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitDeposit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      elevation: 3,
                      shadowColor: const Color(0xFF1B5E20).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Menyimpan...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Submit Setoran',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ],
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFF2E7D32) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: isPrimary ? 2 : 0,
      shadowColor: isPrimary ? const Color(0xFF2E7D32).withOpacity(0.3) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isPrimary
                ? null
                : Border.all(color: Colors.grey[300]!, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 13,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
