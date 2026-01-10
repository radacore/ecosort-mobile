import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scoreboard_entry.dart';
import '../utils/constants.dart';

class ScoreboardService {
  static const String baseUrl = AppConstants.BASE_URL;

  Future<ScoreboardResponse?> fetchScoreboard(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/scoreboard'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final topScoresJson = decoded['top_scores'];
          final currentUserJson = decoded['current_user'];

          final topScores = <ScoreboardEntry>[];

          if (topScoresJson is List) {
            for (final item in topScoresJson) {
              if (item is Map<String, dynamic>) {
                topScores.add(ScoreboardEntry.fromJson(item));
              }
            }
          }

          ScoreboardEntry? currentUser;
          if (currentUserJson is Map<String, dynamic>) {
            currentUser = ScoreboardEntry.fromJson(currentUserJson);
          }

          return ScoreboardResponse(topScores: topScores, currentUser: currentUser);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class ScoreboardResponse {
  final List<ScoreboardEntry> topScores;
  final ScoreboardEntry? currentUser;

  ScoreboardResponse({required this.topScores, required this.currentUser});
}
