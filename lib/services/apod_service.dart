import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/apod_entry.dart';

/// Fetches NASA's Astronomy Picture of the Day.
///
/// Uses NASA's public `DEMO_KEY`, which is rate-limited (30 requests/hour,
/// 50/day per IP) — fine for a demo app, but the result is cached in memory
/// per calendar day so reopening this panel doesn't re-fetch needlessly.
class ApodService {
  static const _endpoint = 'https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY';

  static ApodEntry? _cached;
  static String? _cachedForDate;

  static Future<ApodEntry> fetch() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_cached != null && _cachedForDate == today) {
      return _cached!;
    }

    final response = await http
        .get(Uri.parse(_endpoint))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 429) {
      throw Exception('NASA\'s demo API is rate-limited right now — try again in a bit.');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to load (HTTP ${response.statusCode}).');
    }

    final entry = ApodEntry.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    _cached = entry;
    _cachedForDate = today;
    return entry;
  }
}
