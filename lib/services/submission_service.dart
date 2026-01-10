import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/submission.dart';

class SubmissionService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Submit waste collection
  Future<Submission?> submitWaste({
    required String wasteTypeId,
    required double volume,
    required double weight,
    required int points,
    File? image,
  }) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) return null;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/setoran-sampah'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['waste_type_id'] = wasteTypeId;
      request.fields['volume'] = volume.toString();
      request.fields['weight'] = weight.toString();
      request.fields['points'] = points.toString();

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
          ),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(respStr);
        return Submission.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Calculate points based on waste type and volume
  static int calculatePoints(double volume, double pointsPerKg) {
    // Convert volume (liters) to weight (kg) with assumption 1L = 1kg
    final weight = volume;
    return (weight * pointsPerKg).toInt();
  }
}