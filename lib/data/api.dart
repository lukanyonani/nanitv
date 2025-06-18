import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/iptv_models.dart';

// ==========================================
// 1. API SERVICE WITH LIVELY LOGS
// ==========================================

class IptvApiService {
  static const String _baseUrl = 'https://iptv-org.github.io/api';
  final http.Client _client;

  IptvApiService({http.Client? client}) : _client = client ?? http.Client() {
    print('✨ [IPTV] Service initialized with base URL $_baseUrl');
  }

  /// Generic helper to fetch JSON and map to models
  Future<List<T>> _fetchList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final url = '$_baseUrl/$endpoint';
    print('🚀 [IPTV] GET $url');
    try {
      final response = await _client.get(Uri.parse(url));
      print('📬 [IPTV] Response ${response.statusCode} for $endpoint');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ [IPTV] Parsed ${data.length} records from $endpoint');
        return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      } else {
        final msg = '❌ [IPTV] Failed to load $endpoint: ${response.statusCode}';
        print(msg);
        throw Exception(msg);
      }
    } catch (e) {
      print('🔥 [IPTV] Error fetching $endpoint: $e');
      rethrow;
    }
  }

  Future<List<Channel>> fetchChannels() {
    print('📺 [IPTV] fetchChannels() called');
    return _fetchList('channels.json', Channel.fromJson);
  }

  Future<List<Feed>> fetchFeeds() {
    print('🎙️ [IPTV] fetchFeeds() called');
    return _fetchList('feeds.json', Feed.fromJson);
  }

  Future<List<StreamInfo>> fetchStreams() {
    print('🌊 [IPTV] fetchStreams() called');
    return _fetchList('streams.json', StreamInfo.fromJson);
  }

  Future<List<Guide>> fetchGuides() {
    print('📖 [IPTV] fetchGuides() called');
    return _fetchList('guides.json', Guide.fromJson);
  }

  Future<List<Category>> fetchCategories() {
    print('🏷️ [IPTV] fetchCategories() called');
    return _fetchList('categories.json', Category.fromJson);
  }

  Future<List<Language>> fetchLanguages() {
    print('🗣️ [IPTV] fetchLanguages() called');
    return _fetchList('languages.json', Language.fromJson);
  }

  Future<List<Country>> fetchCountries() {
    print('🌍 [IPTV] fetchCountries() called');
    return _fetchList('countries.json', Country.fromJson);
  }

  Future<List<Subdivision>> fetchSubdivisions() {
    print('🏙️ [IPTV] fetchSubdivisions() called');
    return _fetchList('subdivisions.json', Subdivision.fromJson);
  }

  Future<List<Region>> fetchRegions() {
    print('📈 [IPTV] fetchRegions() called');
    return _fetchList('regions.json', Region.fromJson);
  }

  Future<List<TimezoneModel>> fetchTimezones() {
    print('⏰ [IPTV] fetchTimezones() called');
    return _fetchList('timezones.json', TimezoneModel.fromJson);
  }

  Future<List<BlocklistItem>> fetchBlocklist() {
    print('🚫 [IPTV] fetchBlocklist() called');
    return _fetchList('blocklist.json', BlocklistItem.fromJson);
  }

  void dispose() {
    _client.close();
    print('👋 [IPTV] Service disposed');
  }
}
