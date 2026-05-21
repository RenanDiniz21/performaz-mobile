import '../../shared/models/achievement.dart';
import '../network/api_client.dart';

class GamificationRepository {
  GamificationRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<Map<String, dynamic>> fetchVendorStats(String vendorId) async {
    final response = await apiClient.get('/gamification/vendor/$vendorId/stats');
    return response.data as Map<String, dynamic>;
  }

  Future<List<Achievement>> fetchAchievements(String vendorId) async {
    final response = await apiClient.get('/gamification/vendor/$vendorId/achievements');
    final list = response.data as List;
    return list.map((e) => Achievement.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    String metric = 'xp',
    String period = 'weekly',
  }) async {
    final response = await apiClient.get(
      '/gamification/leaderboard',
      queryParameters: {'metric': metric, 'period': period},
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }
}
