import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/iptv_models.dart';
import '../providers/providers.dart';

// ==========================================
// 1. CHANNELS VIEWMODEL
// ==========================================

class ChannelsViewModel {
  final Ref _ref;

  ChannelsViewModel(this._ref);

  // Core data access
  AsyncValue<List<Channel>> get channels =>
      _ref.watch(filteredChannelsProvider);
  AsyncValue<List<Country>> get countries => _ref.watch(countriesProvider);
  AsyncValue<List<Category>> get categories => _ref.watch(categoriesProvider);
  AsyncValue<List<String>> get availableCountries =>
      _ref.watch(availableCountriesProvider);
  AsyncValue<List<String>> get availableCategories =>
      _ref.watch(availableCategoriesProvider);

  // Filter state
  ChannelFilters get filters => _ref.watch(channelFiltersProvider);
  ChannelFiltersNotifier get filtersNotifier =>
      _ref.read(channelFiltersProvider.notifier);

  // Convenience methods for UI
  void searchChannels(String query) {
    filtersNotifier.updateSearchQuery(query);
  }

  void filterByCountry(String? countryCode) {
    filtersNotifier.updateCountryFilter(countryCode);
  }

  void filterByCategory(String? categoryId) {
    filtersNotifier.updateCategoryFilter(categoryId);
  }

  void toggleNsfw() {
    filtersNotifier.toggleNsfwChannels();
  }

  void toggleActiveOnly() {
    filtersNotifier.toggleActiveOnly();
  }

  void clearAllFilters() {
    filtersNotifier.clearFilters();
  }

  // Helper methods
  String getCountryName(String countryCode) {
    return countries.maybeWhen(
      data: (countries) {
        final country = countries.firstWhere(
          (c) => c.code == countryCode,
          orElse: () => Country(name: countryCode, code: countryCode),
        );
        return country.name;
      },
      orElse: () => countryCode,
    );
  }

  String getCategoryName(String categoryId) {
    return categories.maybeWhen(
      data: (categories) {
        final category = categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => Category(id: categoryId, name: categoryId),
        );
        return category.name;
      },
      orElse: () => categoryId,
    );
  }

  // Statistics
  int get totalChannelsCount {
    return channels.maybeWhen(
      data: (channels) => channels.length,
      orElse: () => 0,
    );
  }

  bool get hasActiveFilters {
    return filters.countryFilter != null ||
        filters.categoryFilter != null ||
        filters.languageFilter != null ||
        filters.searchQuery.isNotEmpty ||
        !filters.showActiveOnly ||
        filters.showNsfwChannels;
  }
}

// Provider for ChannelsViewModel
final channelsViewModelProvider = Provider<ChannelsViewModel>((ref) {
  return ChannelsViewModel(ref);
});

// ==========================================
// 2. CHANNEL DETAIL VIEWMODEL
// ==========================================

class ChannelDetailViewModel {
  final Ref _ref;
  final String channelId;

  ChannelDetailViewModel(this._ref, this.channelId);

  // Core data access
  AsyncValue<ChannelDetails> get channelDetails =>
      _ref.watch(channelDetailsProvider(channelId));
  AsyncValue<List<Feed>> get feeds =>
      _ref.watch(feedsForChannelProvider(channelId));
  AsyncValue<List<StreamInfo>> get streams =>
      _ref.watch(streamsForChannelProvider(channelId));
  AsyncValue<List<Guide>> get guides =>
      _ref.watch(guidesForChannelProvider(channelId));

  // Convenience getters
  Channel? get channel {
    return channelDetails.maybeWhen(
      data: (details) => details.channel,
      orElse: () => null,
    );
  }

  StreamInfo? get bestStream {
    return channelDetails.maybeWhen(
      data: (details) => details.bestQualityStream,
      orElse: () => null,
    );
  }

  Feed? get mainFeed {
    return channelDetails.maybeWhen(
      data: (details) => details.mainFeed,
      orElse: () => null,
    );
  }

  // Stream selection methods
  List<StreamInfo> getStreamsByQuality() {
    return streams.maybeWhen(
      data: (streams) {
        final qualityOrder = ['1080p', '720p', '480p', '360p', '240p'];
        final streamsCopy = List<StreamInfo>.from(streams);

        streamsCopy.sort((a, b) {
          final aIndex = qualityOrder.indexOf(a.quality ?? '');
          final bIndex = qualityOrder.indexOf(b.quality ?? '');

          if (aIndex == -1 && bIndex == -1) return 0;
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;

          return aIndex.compareTo(bIndex);
        });

        return streamsCopy;
      },
      orElse: () => [],
    );
  }

  List<String> get availableQualities {
    return streams.maybeWhen(
      data: (streams) {
        final qualities = streams
            .map((s) => s.quality)
            .where((q) => q != null)
            .cast<String>()
            .toSet()
            .toList();

        const qualityOrder = ['1080p', '720p', '480p', '360p', '240p'];
        qualities.sort((a, b) {
          final aIndex = qualityOrder.indexOf(a);
          final bIndex = qualityOrder.indexOf(b);

          if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;

          return aIndex.compareTo(bIndex);
        });

        return qualities;
      },
      orElse: () => [],
    );
  }

  StreamInfo? getStreamByQuality(String quality) {
    return streams.maybeWhen(
      data: (streams) => streams.firstWhere(
        (s) => s.quality == quality,
        orElse: () => streams.isNotEmpty ? streams.first : null as StreamInfo,
      ),
      orElse: () => null,
    );
  }

  // Helper methods
  bool get hasStreams {
    return streams.maybeWhen(
      data: (streams) => streams.isNotEmpty,
      orElse: () => false,
    );
  }

  bool get hasFeeds {
    return feeds.maybeWhen(
      data: (feeds) => feeds.isNotEmpty,
      orElse: () => false,
    );
  }

  bool get hasGuides {
    return guides.maybeWhen(
      data: (guides) => guides.isNotEmpty,
      orElse: () => false,
    );
  }

  int get streamCount {
    return streams.maybeWhen(
      data: (streams) => streams.length,
      orElse: () => 0,
    );
  }

  int get feedCount {
    return feeds.maybeWhen(data: (feeds) => feeds.length, orElse: () => 0);
  }
}

// Provider for ChannelDetailViewModel
final channelDetailViewModelProvider =
    Provider.family<ChannelDetailViewModel, String>((ref, channelId) {
      return ChannelDetailViewModel(ref, channelId);
    });
