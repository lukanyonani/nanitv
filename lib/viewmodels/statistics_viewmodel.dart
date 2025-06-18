import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/iptv_models.dart';
import '../providers/providers.dart';

// ==========================================
// 10. STATISTICS VIEWMODEL
// ==========================================

class StatisticsViewModel {
  final Ref _ref;

  StatisticsViewModel(this._ref);

  // Core statistics
  AsyncValue<Map<String, int>> get channelStats =>
      _ref.watch(channelStatisticsProvider);

  // Detailed analytics
  AsyncValue<Map<String, dynamic>> get detailedStats {
    final channelsAsync = _ref.watch(channelsProvider);
    final streamsAsync = _ref.watch(streamsProvider);
    final feedsAsync = _ref.watch(feedsProvider);
    final guidesAsync = _ref.watch(guidesProvider);

    return channelsAsync.when(
      data: (channels) {
        return streamsAsync.when(
          data: (streams) {
            return feedsAsync.when(
              data: (feeds) {
                return guidesAsync.when(
                  data: (guides) {
                    final stats = _calculateDetailedStats(
                      channels,
                      streams,
                      feeds,
                      guides,
                    );
                    return AsyncValue.data(stats);
                  },
                  loading: () => const AsyncValue.loading(),
                  error: (error, stackTrace) =>
                      AsyncValue.error(error, stackTrace),
                );
              },
              loading: () => const AsyncValue.loading(),
              error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
            );
          },
          loading: () => const AsyncValue.loading(),
          error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
        );
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    );
  }

  Map<String, dynamic> _calculateDetailedStats(
    List<Channel> channels,
    List<StreamInfo> streams,
    List<Feed> feeds,
    List<Guide> guides,
  ) {
    // Country distribution
    final countryDistribution = <String, int>{};
    for (final channel in channels) {
      countryDistribution[channel.country] =
          (countryDistribution[channel.country] ?? 0) + 1;
    }

    // Category distribution
    final categoryDistribution = <String, int>{};
    for (final channel in channels) {
      if (channel.categories != null) {
        for (final category in channel.categories!) {
          categoryDistribution[category] =
              (categoryDistribution[category] ?? 0) + 1;
        }
      }
    }

    // Quality distribution
    final qualityDistribution = <String, int>{};
    for (final stream in streams) {
      final quality = stream.quality ?? 'unknown';
      qualityDistribution[quality] = (qualityDistribution[quality] ?? 0) + 1;
    }

    // Language distribution
    final languageDistribution = <String, int>{};
    for (final feed in feeds) {
      if (feed.languages != null) {
        for (final language in feed.languages!) {
          languageDistribution[language] =
              (languageDistribution[language] ?? 0) + 1;
        }
      }
    }

    return {
      'total_channels': channels.length,
      'active_channels': channels.where((c) => c.isActive).length,
      'inactive_channels': channels.where((c) => !c.isActive).length,
      'nsfw_channels': channels.where((c) => c.isNsfw).length,
      'total_streams': streams.length,
      'total_feeds': feeds.length,
      'total_guides': guides.length,
      'channels_with_streams': streams.map((s) => s.channel).toSet().length,
      'channels_with_feeds': feeds.map((f) => f.channel).toSet().length,
      'channels_with_guides': guides.map((g) => g.channel).toSet().length,
      'unique_countries': countryDistribution.length,
      'unique_categories': categoryDistribution.length,
      'unique_qualities': qualityDistribution.length,
      'unique_languages': languageDistribution.length,
      'country_distribution': countryDistribution,
      'category_distribution': categoryDistribution,
      'quality_distribution': qualityDistribution,
      'language_distribution': languageDistribution,
      'top_countries': _getTopItems(countryDistribution, 10),
      'top_categories': _getTopItems(categoryDistribution, 10),
      'top_qualities': _getTopItems(qualityDistribution, 5),
      'top_languages': _getTopItems(languageDistribution, 10),
    };
  }

  List<MapEntry<String, int>> _getTopItems(
    Map<String, int> distribution,
    int limit,
  ) {
    final entries = distribution.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  // Quick access methods
  String get quickSummary {
    return channelStats.maybeWhen(
      data: (stats) {
        final total = stats['total_channels'] ?? 0;
        final active = stats['active_channels'] ?? 0;
        final streams = stats['total_streams'] ?? 0;
        return '$total channels ($active active) • $streams streams';
      },
      orElse: () => 'Loading statistics...',
    );
  }

  double get activeChannelPercentage {
    return channelStats.maybeWhen(
      data: (stats) {
        final total = stats['total_channels'] ?? 0;
        final active = stats['active_channels'] ?? 0;
        if (total == 0) return 0.0;
        return (active / total) * 100;
      },
      orElse: () => 0.0,
    );
  }
}

// Provider for StatisticsViewModel
final statisticsViewModelProvider = Provider<StatisticsViewModel>((ref) {
  return StatisticsViewModel(ref);
});
