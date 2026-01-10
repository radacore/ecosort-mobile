import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/kecamatan.dart';
import '../utils/constants.dart';

class KecamatanService {
  static const String baseUrl = AppConstants.BASE_URL;

  // Get all kecamatan - with network debugging
  Future<List<Kecamatan>> getKecamatan() async {
    try {
      final url = '$baseUrl/kecamatan';
      print('=== FETCHING KECAMATAN DATA ===');
      print('Request URL: $url');
      print('Base URL: $baseUrl');
      
      // Test if we can reach the server at all
      try {
        final testResponse = await http.get(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 10));
        print('Base URL connectivity test - Status: ${testResponse.statusCode}');
      } catch (e) {
        print('Base URL connectivity test failed: $e');
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 15));

      print('Kecamatan API Response Status: ${response.statusCode}');
      print('Kecamatan API Response Headers: ${response.headers}');
      print('Kecamatan API Response Body Length: ${response.body.length}');
      
      // Show first 500 characters of response for debugging
      if (response.body.length > 0) {
        String preview = response.body.length > 500 
            ? '${response.body.substring(0, 500)}...' 
            : response.body;
        print('Kecamatan API Response Body Preview: $preview');
      }

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        print('Parsed Data Type: ${data.runtimeType}');
        
        // Handle the actual data parsing
        List<Kecamatan> kecamatanList = [];

        // Most common case: direct array of kecamatan objects
        if (data is List) {
          print('Processing direct array with ${data.length} items');
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              final id = item['id']?.toString() ?? '';
              final name = item['nama']?.toString() ?? item['name']?.toString() ?? '';
              if (id.isNotEmpty && name.isNotEmpty) {
                kecamatanList.add(Kecamatan(id: id, name: name));
              }
            }
          }
        }
        // Laravel API format: wrapped in 'data' key
        else if (data is Map<String, dynamic> && data.containsKey('data')) {
          final dynamic kecamatanData = data['data'];
          print('Processing Laravel wrapped response');
          if (kecamatanData is List) {
            print('Processing wrapped array with ${kecamatanData.length} items');
            for (var item in kecamatanData) {
              if (item is Map<String, dynamic>) {
                final id = item['id']?.toString() ?? '';
                final name = item['nama']?.toString() ?? item['name']?.toString() ?? '';
                if (id.isNotEmpty && name.isNotEmpty) {
                  kecamatanList.add(Kecamatan(id: id, name: name));
                }
              }
            }
          }
        }
        // Specific format: wrapped in 'kecamatan' key (your API format)
        else if (data is Map<String, dynamic> && data.containsKey('kecamatan')) {
          final dynamic kecamatanData = data['kecamatan'];
          print('Processing kecamatan wrapped response');
          if (kecamatanData is List) {
            print('Processing kecamatan array with ${kecamatanData.length} items');
            for (var item in kecamatanData) {
              if (item is Map<String, dynamic>) {
                final id = item['id']?.toString() ?? '';
                final name = item['nama']?.toString() ?? item['name']?.toString() ?? '';
                if (id.isNotEmpty && name.isNotEmpty) {
                  kecamatanList.add(Kecamatan(id: id, name: name));
                }
              }
            }
          }
        }
        // Flat object map format
        else if (data is Map<String, dynamic>) {
          print('Processing flat map response');
          data.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              final id = value['id']?.toString() ?? key.toString();
              final name = value['nama']?.toString() ?? value['name']?.toString() ?? '';
              if (name.isNotEmpty) {
                kecamatanList.add(Kecamatan(id: id, name: name));
              }
            }
          });
        }
        
        print('Successfully parsed ${kecamatanList.length} kecamatan');
        if (kecamatanList.isNotEmpty) {
          print('First 3 kecamatan:');
          for (int i = 0; i < kecamatanList.length && i < 3; i++) {
            print('  ${i + 1}. ${kecamatanList[i].name}');
          }
        }
        
        return kecamatanList;
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to load kecamatan. Server returned status ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('TIMEOUT ERROR: Request timed out - $e');
      throw Exception('Network timeout: Please check your internet connection');
    } catch (e) {
      print('KECAMATAN SERVICE ERROR: $e');
      throw Exception('Failed to load kecamatan: $e');
    }
  }
}