import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const _bestScoreKey = 'best_quiz_score';
  static const _lastPlanetKey = 'last_selected_planet';

  static Future<int?> loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestScoreKey);
  }

  static Future<void> saveBestScoreIfHigher(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_bestScoreKey) ?? 0;
    if (score > current) {
      await prefs.setInt(_bestScoreKey, score);
    }
  }

  static Future<String?> loadLastPlanet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastPlanetKey);
  }

  static Future<void> saveLastPlanet(String planetName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlanetKey, planetName);
  }
}
