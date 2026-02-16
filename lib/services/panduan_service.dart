import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/panduan_model.dart';
import '../utils/constants.dart';

class PanduanService {
  static const String baseUrl = AppConstants.BASE_URL;

  Future<List<PanduanItem>> fetchPanduan() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/panduan'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final List data = decoded['data'] as List;
          return data
              .map((item) => PanduanItem.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
