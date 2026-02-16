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
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message, VoidCallback? onOk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Berhasil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onOk != null) onOk();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Mengurangi ukuran file
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
        imageQuality: 50, // Mengurangi ukuran file
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

    // Tambahkan pengecekan tambahan untuk file
    if (!await _imageFile!.exists()) {
      _showErrorDialog(
        'File gambar tidak ditemukan. Silakan pilih gambar kembali.',
      );
      print('Image file does not exist at path: ${_imageFile!.path}');
      return;
    }

    // Cek ukuran file
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
      // Membuat request multipart untuk upload ke API volume detection
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.13:5000/detect-volume'),
      );

      // Menambahkan file gambar
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _imageFile!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Menambahkan jenis sampah
      // Untuk API deteksi volume, gunakan format lowercase
      String trashTypeValueForDetection = _getTrashTypeValueForDetection(
        _selectedTrashType!,
      );
      request.fields['trash_type'] = trashTypeValueForDetection;

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('API Response: $responseBody');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Cek apakah response adalah HTML bukan JSON
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

        // Validasi bahwa nilai bukan nol
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

    // Tambahkan pengecekan tambahan untuk file
    if (!await _imageFile!.exists()) {
      _showErrorDialog(
        'File gambar tidak ditemukan. Silakan pilih gambar kembali.',
      );
      print('Image file does not exist at path: ${_imageFile!.path}');
      return;
    }

    // Cek ukuran file
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
      // Mendapatkan token dari AuthService
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        _showErrorDialog('Sesi tidak valid, silakan login kembali');
        print('Token is null');
        return;
      }

      // Menggunakan DepositService untuk mendapatkan informasi pengguna
      final depositService = DepositService();
      final userInfo = await depositService.getUserInfo(token);

      if (userInfo == null) {
        _showErrorDialog('Gagal mendapatkan informasi pengguna');
        print('User info is null');
        return;
      }

      String penggunaId = userInfo['id'].toString();
      String kecamatanId = userInfo['kecamatan_id']?.toString() ?? '';

      // Menggunakan DepositService untuk submit deposit
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
          // Reset form setelah submit berhasil
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
      appBar: AppBar(
        title: const Text('Scan Setor Sampah'),
        backgroundColor: const Color(0xFF368b3a),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Foto Sampah',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Tombol untuk memilih gambar dari galeri atau kamera
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeri'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF368b3a),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Kamera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF368b3a),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tampilkan gambar yang dipilih
              if (_selectedImage != null)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              const Text(
                'Jenis Sampah',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Dropdown jenis sampah
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  value: _selectedTrashType,
                  items: _trashTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTrashType = newValue;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Tombol proses
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF368b3a),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Memproses...'),
                          ],
                        )
                      : const Text('Proses'),
                ),
              ),
              const SizedBox(height: 20),

              // Hasil proses
              if (_volumeLiters != null || _weightKg != null)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hasil Pemrosesan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_volumeLiters != null)
                          _buildResultItem(
                            'Volume (Liter)',
                            '${_volumeLiters!.toStringAsFixed(2)} L',
                          ),
                        if (_weightKg != null)
                          _buildResultItem(
                            'Berat (Kg)',
                            '${_weightKg!.toStringAsFixed(2)} Kg',
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Tombol submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || _volumeLiters == null
                      ? null
                      : _submitDeposit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _volumeLiters != null
                        ? const Color(0xFF368b3a)
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Menyimpan...'),
                          ],
                        )
                      : const Text('Submit Setoran'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
