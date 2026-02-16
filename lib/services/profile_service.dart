import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class ProfileService {
  static const String baseUrl = AppConstants.BASE_URL;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Get user profile
  Future<User?> getProfile() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        print('No token found for profile request');
        return null;
      }

      print('Making profile request with token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/profil'), // Use /profil instead of /profile
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      print('Profile response status: ${response.statusCode}');
      print('Profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Profile data: $data');
        return User.fromJson(data);
      } else {
        print('Profile request failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Profile request error: $e');
      return null;
    }
  }

  // Update user profile
  Future<User?> updateProfile({
    String? name,
    String? address,
    String? district, // This will be kecamatan_id now
    String? password,
    String? confirmPassword,
  }) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        print('No token found for profile update request');
        return null;
      }

      print(
        'Updating profile with name: $name, address: $address, district (kecamatan_id): $district',
      );
      if (password != null && password.isNotEmpty) {
        print('Password will be updated');
      }

      // Prepare the data to send - using the correct field names for your API
      final Map<String, dynamic> requestData = {};
      if (name != null) requestData['nama'] = name; // Use 'nama' not 'name'
      if (address != null)
        requestData['alamat'] = address; // Use 'alamat' not 'address'

      // If district is provided, send it as 'kecamatan_id' (the ID, not name)
      if (district != null) {
        requestData['kecamatan_id'] =
            int.tryParse(district) ?? district; // Send as integer if possible
      }

      // If password is provided, send it and confirmation
      if (password != null && password.isNotEmpty) {
        requestData['password'] = password;
        requestData['password_confirmation'] = confirmPassword ?? password;
      }

      print('Sending request data: $requestData');

      final response = await http.put(
        Uri.parse('$baseUrl/profil'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      print('Update profile response status: ${response.statusCode}');
      print('Update profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Updated profile data: $data');
        return User.fromJson(data);
      } else {
        print('Update profile failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Update profile error: $e');
      return null;
    }
  }

  // Upload avatar
  Future<User?> uploadAvatar(String filePath) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        print('No token found for avatar upload');
        return null;
      }

      print('Uploading avatar with token: $token');
      print('File path: $filePath');

      // Using Dio for multipart form data upload
      final dio = Dio();

      // Configure the dio client
      dio.options.headers['Authorization'] = 'Bearer $token';

      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          filePath,
          filename: 'avatar.jpg',
        ),
      });

      final response = await dio.post(
        '$baseUrl/profil/avatar/upload',
        data: formData,
      );

      print('Avatar upload response status: ${response.statusCode}');
      print('Avatar upload response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = response.data;
        print('Avatar upload data: $data');
        return User.fromJson(data);
      } else {
        print('Avatar upload failed with status: ${response.statusCode}');
        print('Response body: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Avatar upload error: $e');
      return null;
    }
  }
}
