import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageUtils {
  static const String _activityHistoryKey = 'activity_history';

  static Future<void> saveActivityHistory(List<ActivityResult> history) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = history.map((activity) => activity.toJson()).toList();
    final String jsonString = jsonEncode(jsonList);
    await prefs.setString(_activityHistoryKey, jsonString);
  }

  static Future<List<ActivityResult>> loadActivityHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_activityHistoryKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => ActivityResult.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}