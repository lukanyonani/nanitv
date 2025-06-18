import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/iptv_models.dart';
import '../providers/providers.dart';
// ==========================================
// 4. FEEDS VIEWMODEL
// ==========================================

class FeedsViewModel {
  final Ref _ref;

  FeedsViewModel(this._ref);

  // Core data access
  AsyncValue<List<Feed>> get allFeeds => _ref.watch(feedsProvider);

  // Helper methods
  List<Feed> getFeedsForChannel(String channelId) {
    return _ref
        .watch(feedsForChannelProvider(channelId))
        .maybeWhen(data: (feeds) => feeds, orElse: () => []);
  }

  // Feed analysis
  Map<String, List<Feed>> groupFeedsByChannel() {
    return allFeeds.maybeWhen(
      data: (feeds) {
        final grouped = <String, List<Feed>>{};
        for (final feed in feeds) {
          final channelId = feed.channel ?? 'unknown';
          grouped.putIfAbsent(channelId, () => []).add(feed);
        }
        return grouped;
      },
      orElse: () => {},
    );
  }

  Map<String, int> getLanguageDistribution() {
    return allFeeds.maybeWhen(
      data: (feeds) {
        final distribution = <String, int>{};
        for (final feed in feeds) {
          if (feed.languages != null) {
            for (final language in feed.languages!) {
              distribution[language] = (distribution[language] ?? 0) + 1;
            }
          }
        }
        return distribution;
      },
      orElse: () => {},
    );
  }

  List<Feed> getMainFeeds() {
    return allFeeds.maybeWhen(
      data: (feeds) => feeds.where((feed) => feed.isMain).toList(),
      orElse: () => [],
    );
  }

  List<Feed> getFeedsByLanguage(String languageCode) {
    return allFeeds.maybeWhen(
      data: (feeds) => feeds
          .where((feed) => feed.languages?.contains(languageCode) ?? false)
          .toList(),
      orElse: () => [],
    );
  }

  List<String> get availableLanguages {
    return allFeeds.maybeWhen(
      data: (feeds) {
        final languages = <String>{};
        for (final feed in feeds) {
          if (feed.languages != null) {
            languages.addAll(feed.languages!);
          }
        }
        return languages.toList()..sort();
      },
      orElse: () => [],
    );
  }

  int get totalFeedsCount {
    return allFeeds.maybeWhen(data: (feeds) => feeds.length, orElse: () => 0);
  }

  int get mainFeedsCount {
    return allFeeds.maybeWhen(
      data: (feeds) => feeds.where((feed) => feed.isMain).length,
      orElse: () => 0,
    );
  }

  int get channelsWithFeedsCount {
    final grouped = groupFeedsByChannel();
    return grouped.keys.length;
  }
}

// Provider for FeedsViewModel
final feedsViewModelProvider = Provider<FeedsViewModel>((ref) {
  return FeedsViewModel(ref);
});
