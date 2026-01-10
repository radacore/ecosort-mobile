import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AuthService {
  static const String baseUrl = AppConstants.BASE_URL;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Register a new user - PROPER VALIDATION APPROACH
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      print('=== REGISTER ATTEMPT ===');
      
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'nama': name,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
        }),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            // Check if the response contains expected fields (like user data or message)
            if (data.containsKey('pengguna') || data.containsKey('message')) {
              print('✅ REGISTRATION SUCCESSFUL - VALID RESPONSE');
              return {
                'success': true,
                'message': data['message']?.toString() ?? 'Registration successful!',
                'statusCode': response.statusCode,
                'userData': data['pengguna'] // Include user data if available
              };
            } else {
              print('❌ INVALID REGISTRATION RESPONSE - MISSING EXPECTED FIELDS');
              return {
                'success': false,
                'error': 'Invalid response from server',
                'statusCode': response.statusCode
              };
            }
          } else {
            print('❌ INVALID REGISTRATION RESPONSE FORMAT');
            return {
              'success': false,
              'error': 'Invalid response format from server',
              'statusCode': response.statusCode
            };
          }
        } catch (e) {
          print('❌ COULD NOT PARSE REGISTRATION RESPONSE: $e');
          return {
            'success': false,
            'error': 'Could not parse server response',
            'statusCode': response.statusCode
          };
        }
      } else {
        // Parse error message from response if available
        String errorMessage = 'Registration failed with status ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> && errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          } else if (errorData is Map<String, dynamic> && errorData['errors'] != null) {
            // Handle Laravel validation errors format
            final errors = errorData['errors'] as Map<String, dynamic>?;
            if (errors != null) {
              errorMessage = errors.values.first.toString();
            }
          }
        } catch (e) {
          print('Could not parse registration error response body');
        }
        
        print('❌ REGISTRATION FAILED - $errorMessage');
        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('❌ REGISTER NETWORK ERROR: $e');
      return {
        'success': false,
        'error': 'Network error - please check connection'
      };
    }
  }

  // Login user - PROPER VALIDATION APPROACH
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('=== LOGIN ATTEMPT ===');
      print('Base URL: $baseUrl');
      final url = Uri.parse('$baseUrl/login');
      print('Login URL: $url');
      
      // Test koneksi ke server
      try {
        final testResponse = await http.get(Uri.parse(baseUrl));
        print('Test connection response: ${testResponse.statusCode}');
      } catch (e) {
        print('Test connection error: $e');
      }
      
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Login request timed out');
        },
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      
      // Parse response to look for tokens
      String? token;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            // Look for access_token specifically (as per your API response)
            token = data['access_token']?.toString();
            
            // Only consider login successful if we have a valid token
            if (token != null && token.isNotEmpty) {
              // Save token if found
              await _secureStorage.write(key: 'token', value: token);
              print('✅ TOKEN SAVED: $token');
              
              // Create user object from response if available
              User? user;
              if (data.containsKey('pengguna')) {
                user = User.fromJson(data);
              }
              
              return {
                'success': true,
                'token': token,
                'message': 'Login successful!',
                'statusCode': response.statusCode,
                'user': user // Include user object
              };
            } else {
              print('❌ ACCESS_TOKEN NOT FOUND IN RESPONSE');
              return {
                'success': false,
                'error': 'Invalid response from server - missing access token',
                'statusCode': response.statusCode
              };
            }
          } else {
            print('❌ INVALID RESPONSE FORMAT');
            return {
              'success': false,
              'error': 'Invalid response format from server',
              'statusCode': response.statusCode
            };
          }
        } catch (e) {
          print('❌ COULD NOT PARSE RESPONSE BODY FOR TOKEN: $e');
          return {
            'success': false,
            'error': 'Could not parse server response',
            'statusCode': response.statusCode
          };
        }
      } else {
        // Parse error message from response if available
        String errorMessage = 'Login failed with status ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> && errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } catch (e) {
          print('Could not parse error response body');
        }
        
        print('❌ LOGIN FAILED - $errorMessage');
        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('❌ LOGIN NETWORK ERROR: $e');
      return {
        'success': false,
        'error': 'Network error - please check connection'
      };
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'token');
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Get current user data
  Future<User?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        print('No token found, cannot get user data');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get user response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return User.fromJson(data);
        }
      }
      print('Failed to get user data');
      return null;
    } catch (e) {
      print('❌ GET USER NETWORK ERROR: $e');
      return null;
    }
  }

  // Logout user - with backend API call
  Future<Map<String, dynamic>> logout() async {
    try {
      print('=== BACKEND LOGOUT ATTEMPT ===');
      
      // First, get the current token
      final token = await _secureStorage.read(key: 'token');
      if (token == null || token.isEmpty) {
        print('No token found, proceeding with local logout');
        // Clear local storage anyway
        await _secureStorage.delete(key: 'token');
        return {
          'success': true,
          'message': 'Logged out successfully'
        };
      }

      // Call backend logout endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Logout response status: ${response.statusCode}');
      print('Logout response body: ${response.body}');

      // Regardless of backend response, clear local token
      await _secureStorage.delete(key: 'token');
      
      // Consider logout successful if we get 2XX or if there's a network issue
      // (since we've already cleared the local token)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ BACKEND LOGOUT SUCCESSFUL');
        return {
          'success': true,
          'message': 'Logged out successfully',
          'statusCode': response.statusCode
        };
      } else {
        // Even on backend error, we still consider logout successful 
        // because we've cleared the local token
        print('⚠️ BACKEND LOGOUT FAILED, but local logout successful');
        return {
          'success': true,
          'message': 'Logged out successfully',
          'warning': 'Backend logout failed, but local session cleared',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      print('⚠️ LOGOUT NETWORK ERROR: $e');
      // Even on network error, clear local token
      await _secureStorage.delete(key: 'token');
      return {
        'success': true,
        'message': 'Logged out successfully',
        'warning': 'Network error during backend logout, but local session cleared'
      };
    }
  }
}