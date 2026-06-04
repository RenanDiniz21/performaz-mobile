import '../../shared/models/achievement.dart';
import '../network/api_client.dart';

class GamificationRepository {
  GamificationRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<Map<String, dynamic>> fetchVendorStats(String vendorId) async {
    final response = await apiClient.get('/gamification/vendors/$vendorId/stats');
    return response.data as Map<String, dynamic>;
  }

  Future<List<Achievement>> fetchAchievements(String vendorId) async {
    final stats = await fetchVendorStats(vendorId);
    return achievementsFromVendorStats(stats);
  }

  Future<List<Map<String, dynamic>>> fetchVendorGoals(String vendorId) async {
    final response = await apiClient.get(
      '/goals',
      queryParameters: {'vendorId': vendorId},
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchQuests() async {
    final response = await apiClient.get('/quests');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    String metric = 'xp',
    String period = 'mensal',
  }) async {
    final apiMetric = metric == 'faturamento' ? 'revenue' : 'xp';
    final response = await apiClient.get(
      '/gamification/leaderboard',
      queryParameters: {'metric': apiMetric, 'period': period},
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }
}

List<Achievement> achievementsFromVendorStats(Map<String, dynamic> stats) {
  final list = stats['achievements'] as List? ?? [];
  return list
      .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
      .toList();
}
