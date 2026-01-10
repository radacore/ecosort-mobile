import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';
import '../utils/constants.dart';

class NewsService {
  static const String baseUrl = AppConstants.BASE_URL;

  Future<List<NewsArticle>> fetchNews() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/berita'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final List data = decoded['data'] as List;
          return data.map((item) => NewsArticle.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<NewsArticle?> fetchNewsDetail(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/berita/$slug'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return NewsArticle.fromJson(decoded['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
