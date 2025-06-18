import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/iptv_models.dart';
import '../providers/providers.dart';

// ==========================================
// 7. SEARCH VIEWMODEL
// ==========================================

class SearchState {
  final String query;
  final List<Channel> channelResults;
  final List<StreamInfo> streamResults;
  final List<Feed> feedResults;
  final bool isSearching;
  final String? error;

  const SearchState({
    this.query = '',
    this.channelResults = const [],
    this.streamResults = const [],
    this.feedResults = const [],
    this.isSearching = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<Channel>? channelResults,
    List<StreamInfo>? streamResults,
    List<Feed>? feedResults,
    bool? isSearching,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      channelResults: channelResults ?? this.channelResults,
      streamResults: streamResults ?? this.streamResults,
      feedResults: feedResults ?? this.feedResults,
      isSearching: isSearching ?? this.isSearching,
      error: error ?? this.error,
    );
  }

  bool get hasResults =>
      channelResults.isNotEmpty ||
      streamResults.isNotEmpty ||
      feedResults.isNotEmpty;

  int get totalResultsCount =>
      channelResults.length + streamResults.length + feedResults.length;
}

class SearchViewModel extends StateNotifier<SearchState> {
  final Ref _ref;

  SearchViewModel(this._ref) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(query: query, isSearching: true, error: null);

    try {
      final channels = await _searchChannels(query);
      final streams = await _searchStreams(query);
      final feeds = await _searchFeeds(query);

      state = state.copyWith(
        channelResults: channels,
        streamResults: streams,
        feedResults: feeds,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  Future<List<Channel>> _searchChannels(String query) async {
    final channelsAsync = await _ref.read(channelsProvider.future);
    final lowerQuery = query.toLowerCase();

    return channelsAsync.where((channel) {
      final matchesName = channel.name.toLowerCase().contains(lowerQuery);
      final matchesAltNames =
          channel.altNames?.any(
            (altName) => altName.toLowerCase().contains(lowerQuery),
          ) ??
          false;
      final matchesNetwork =
          channel.network?.toLowerCase().contains(lowerQuery) ?? false;
      final matchesCountry = channel.country.toLowerCase().contains(lowerQuery);

      return matchesName || matchesAltNames || matchesNetwork || matchesCountry;
    }).toList();
  }

  Future<List<StreamInfo>> _searchStreams(String query) async {
    final streamsAsync = await _ref.read(streamsProvider.future);
    final lowerQuery = query.toLowerCase();

    return streamsAsync.where((stream) {
      final matchesUrl = stream.url.toLowerCase().contains(lowerQuery);
      final matchesChannel =
          stream.channel?.toLowerCase().contains(lowerQuery) ?? false;
      final matchesQuality =
          stream.quality?.toLowerCase().contains(lowerQuery) ?? false;

      return matchesUrl || matchesChannel || matchesQuality;
    }).toList();
  }

  Future<List<Feed>> _searchFeeds(String query) async {
    final feedsAsync = await _ref.read(feedsProvider.future);
    final lowerQuery = query.toLowerCase();

    return feedsAsync.where((feed) {
      final matchesChannel =
          feed.channel?.toLowerCase().contains(lowerQuery) ?? false;
      final matchesId = feed.id.toLowerCase().contains(lowerQuery);

      return matchesChannel || matchesId;
    }).toList();
  }

  void clearSearch() {
    state = const SearchState();
  }
}

// Provider for SearchViewModel
final searchViewModelProvider =
    StateNotifierProvider<SearchViewModel, SearchState>((ref) {
      return SearchViewModel(ref);
    });
