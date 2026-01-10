import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import '../utils/constants.dart';

class DepositService {

  // Get user info from the new endpoint
  Future<Map<String, dynamic>?> getUserInfo(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/catatan-sampah/user-info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('User info response: ${response.body}');
      print('User info status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('data')) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  // Submit waste deposit to the new endpoint
  Future<Map<String, dynamic>> submitDeposit({
    required String token,
    required String imagePath,
    required String jenisTerdeteksi,
    required double volumeTerdeteksi,
    required double beratKg,
    required String penggunaId,
    required String kecamatanId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.BASE_URL}/catatan-sampah'),
      );

      // Add token to header
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto',
          imagePath,
          contentType: MediaType('image', 'jpeg'), // Menentukan tipe konten
        ),
      );

      // Add other fields
      request.fields['jenis_terdeteksi'] = jenisTerdeteksi;
      request.fields['volume_terdeteksi_liter'] = volumeTerdeteksi.toStringAsFixed(2);
      request.fields['berat_kg'] = beratKg.toStringAsFixed(2);
      request.fields['pengguna_id'] = penggunaId;
      request.fields['kecamatan_id'] = kecamatanId;

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('Submit deposit response: $responseBody');
      print('Submit deposit status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(responseBody);
        return result;
      } else {
        final errorResult = jsonDecode(responseBody);
        return {
          'success': false,
          'message': errorResult['message'] ?? 'Gagal menyimpan data',
        };
      }
    } catch (e) {
      print('Error submitting deposit: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan jaringan: $e',
      };
    }
  }

  
}