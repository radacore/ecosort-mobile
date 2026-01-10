import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import '../utils/constants.dart';
import '../models/user.dart';

class WasteService {
  static const String baseUrl = AppConstants.BASE_URL;

  // Submit waste deposit
  Future<Map<String, dynamic>> submitDeposit({
    required File image,
    required String trashType,
    required double volume,
    required double weight,
    required String token,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/penyetoran'),
      );

      // Add token to headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'bukti_foto',
          image.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Add other data
      request.fields['jenis_sampah'] = trashType;
      request.fields['volume'] = volume.toString();
      request.fields['berat'] = weight.toString();

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      print('Submit deposit response: $responseBody');
      print('Status code: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(responseBody);
        return {
          'success': true,
          'data': result,
          'message': 'Penyetoran berhasil disimpan',
        };
      } else {
        final errorResult = jsonDecode(responseBody);
        return {
          'success': false,
          'error': errorResult['message'] ?? 'Gagal menyimpan penyetoran',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Error submitting deposit: $e');
      return {
        'success': false,
        'error': 'Terjadi kesalahan jaringan: $e',
      };
    }
  }

  // Get user profile after deposit to update points
  Future<User?> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  // Get user's waste deposit history
  Future<List<WasteDeposit>> getWasteHistory({
    required String token,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/riwayat-penyetoran')
          .replace(queryParameters: {'pengguna_id': userId});

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['data'] is List) {
          final list = data['data'] as List;
          return list.map((json) => WasteDeposit.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting waste history: $e');
      return [];
    }
  }
}

class WasteDeposit {
  final int id;
  final String trashType;
  final double volumeLiters;
  final double weightKg;
  final bool isValidated;
  final String timestamp;

  WasteDeposit({
    required this.id,
    required this.trashType,
    required this.volumeLiters,
    required this.weightKg,
    required this.isValidated,
    required this.timestamp,
  });

  factory WasteDeposit.fromJson(Map<String, dynamic> json) {
    return WasteDeposit(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      trashType: json['jenis_sampah']?.toString() ?? '',
      volumeLiters: (json['volume_liter'] is num)
          ? (json['volume_liter'] as num).toDouble()
          : double.tryParse(json['volume_liter']?.toString() ?? '') ?? 0.0,
      weightKg: (json['berat_kg'] is num)
          ? (json['berat_kg'] as num).toDouble()
          : double.tryParse(json['berat_kg']?.toString() ?? '') ?? 0.0,
      isValidated: json['is_divalidasi'] == true ||
          json['is_divalidasi']?.toString() == '1',
      timestamp: json['waktu_setoran']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jenis_sampah': trashType,
      'volume_liter': volumeLiters,
      'berat_kg': weightKg,
      'is_divalidasi': isValidated,
      'waktu_setoran': timestamp,
    };
  }
}