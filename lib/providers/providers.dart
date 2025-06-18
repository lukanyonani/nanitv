import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api.dart';
import '../models/iptv_models.dart';

// ==========================================
// 2. BASE PROVIDERS
// ==========================================

/// Provides a singleton [IptvApiService] and disposes it automatically.
final iptvApiServiceProvider = Provider<IptvApiService>((ref) {
  final service = IptvApiService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Asynchronously loads the full channels list.
final channelsProvider = FutureProvider<List<Channel>>((ref) {
  print('🔄 [Provider] channelsProvider loading...');
  return ref.watch(iptvApiServiceProvider).fetchChannels();
});

/// Asynchronously loads the full feeds list.
final feedsProvider = FutureProvider<List<Feed>>((ref) {
  print('🔄 [Provider] feedsProvider loading...');
  return ref.watch(iptvApiServiceProvider).fetchFeeds();
});

/// Asynchronously loads all streams.
final streamsProvider = FutureProvider<List<StreamInfo>>((ref) {
  print('🔄 [Provider] streamsProvider loading...');
  return ref.watch(iptvApiServiceProvider).fetchStreams();
});

/// Asynchronously loads all guides.
final guidesProvider = FutureProvider<List<Guide>>((ref) {
  print('🔄 [Provider] guidesProvider loading...');
  return ref.watch(iptvApiServiceProvider).fetchGuides();
});

/// Categories taxonomy loader.
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  print('🔄 [Provider] categoriesProvider loading...');
  return ref.watch(iptvApiServiceProvider).fetchCategories();
});

/// Languages taxonomy loader.
final languagesProvider = FutureProvider<List<Language>>((ref) {
  print('🔄 [Provider] languagesProvider loading...');
  return ref.watch(iptvApiServiceProvider).fetchLanguages();
});

/// Countries taxonomy loader.
final countriesProvider = FutureProvider<List<Country>>((ref) {
  print('🔄 [Provider] countriesProvider loading...');
  return ref.watch(iptvApiServiceProvider).fetchCountries();
});

/// Subdivisions taxonomy loader.
final subdivisionsProvider = FutureProvider<List<Subdivision>>((ref) {
  print('🔄 [Provider] subdivisionsProvider loading...');
  return ref.watch(iptvApiServiceProvider).fetchSubdivisions();
});

/// Regions taxonomy loader.
final regionsProvider = FutureProvider<List<Region>>((ref) {
  print('🔄 [Provider] regionsProvider loading...');
  return ref.watch(iptvApiServiceProvider).fetchRegions();
});

/// Timezones taxonomy loader.
final timezonesProvider = FutureProvider<List<TimezoneModel>>((ref) {
  print('🔄 [Provider] timezonesProvider loading...');
  return ref.watch(iptvApiServiceProvider).fetchTimezones();
});

/// Blocklist loader.
final blocklistProvider = FutureProvider<List<BlocklistItem>>((ref) {
  print('🔄 [Provider] blocklistProvider loading...');
  return ref.watch(iptvApiServiceProvider).fetchBlocklist();
});

// ==========================================
// 3. FILTER STATE MANAGEMENT
// ==========================================

class ChannelFilters {
  final String? countryFilter;
  final String? categoryFilter;
  final String? languageFilter;
  final bool showNsfwChannels;
  final bool showActiveOnly;
  final String searchQuery;

  const ChannelFilters({
    this.countryFilter,
    this.categoryFilter,
    this.languageFilter,
    this.showNsfwChannels = false,
    this.showActiveOnly = true,
    this.searchQuery = '',
  });

  ChannelFilters copyWith({
    String? countryFilter,
    String? categoryFilter,
    String? languageFilter,
    bool? showNsfwChannels,
    bool? showActiveOnly,
    String? searchQuery,
  }) {
    return ChannelFilters(
      countryFilter: countryFilter ?? this.countryFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      languageFilter: languageFilter ?? this.languageFilter,
      showNsfwChannels: showNsfwChannels ?? this.showNsfwChannels,
      showActiveOnly: showActiveOnly ?? this.showActiveOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ChannelFiltersNotifier extends StateNotifier<ChannelFilters> {
  ChannelFiltersNotifier() : super(const ChannelFilters());

  void updateCountryFilter(String? country) {
    state = state.copyWith(countryFilter: country);
  }

  void updateCategoryFilter(String? category) {
    state = state.copyWith(categoryFilter: category);
  }

  void updateLanguageFilter(String? language) {
    state = state.copyWith(languageFilter: language);
  }

  void toggleNsfwChannels() {
    state = state.copyWith(showNsfwChannels: !state.showNsfwChannels);
  }

  void toggleActiveOnly() {
    state = state.copyWith(showActiveOnly: !state.showActiveOnly);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearFilters() {
    state = const ChannelFilters();
  }
}

final channelFiltersProvider =
    StateNotifierProvider<ChannelFiltersNotifier, ChannelFilters>((ref) {
      return ChannelFiltersNotifier();
    });

// ==========================================
// 4. COMPUTED PROVIDERS
// ==========================================
/// All “available” channels (not blocked, active only, no NSFW)
final availableChannelsProvider = Provider<AsyncValue<List<Channel>>>((ref) {
  final channelsAsync = ref.watch(channelsProvider);
  final blocklistAsync = ref.watch(blocklistProvider);

  return channelsAsync.when(
    data: (channels) {
      return blocklistAsync.when(
        data: (blocklist) {
          final blockedIds = blocklist.map((b) => b.channel).toSet();
          final available = channels.where((ch) {
            if (blockedIds.contains(ch.id)) return false;
            if (!ch.isActive) return false;
            if (ch.isNsfw) return false;
            return true;
          }).toList();
          return AsyncValue.data(available);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// Filtered Channels Provider
// ------------------------------------------
// 4. COMPUTED PROVIDERS (modified)
// ------------------------------------------

final filteredChannelsProvider = Provider<AsyncValue<List<Channel>>>((ref) {
  final channelsAsync = ref.watch(channelsProvider);
  final blocklistAsync = ref.watch(blocklistProvider);
  final streamsAsync = ref.watch(streamsProvider); // ← new
  final filters = ref.watch(channelFiltersProvider);

  return channelsAsync.when(
    data: (channels) {
      return blocklistAsync.when(
        data: (blocklist) {
          return streamsAsync.when(
            // ← new
            data: (allStreams) {
              final blockedIds = blocklist.map((b) => b.channel).toSet();
              final validStreamIds = allStreams.map((s) => s.channel).toSet();

              final filtered = channels.where((channel) {
                // 1️⃣ Blocklist
                if (blockedIds.contains(channel.id)) return false;
                // 2️⃣ NSFW / active-only
                if (!filters.showNsfwChannels && channel.isNsfw) return false;
                if (filters.showActiveOnly && !channel.isActive) return false;
                // 3️⃣ Country
                final cf = filters.countryFilter;
                if (cf != null && cf != 'ALL' && channel.country != cf)
                  return false;
                // 4️⃣ Category
                final cat = filters.categoryFilter;
                if (cat != null &&
                    (channel.categories == null ||
                        !channel.categories!.contains(cat))) {
                  return false;
                }
                // 5️⃣ Search
                if (filters.searchQuery.isNotEmpty) {
                  final q = filters.searchQuery.toLowerCase();
                  final matchName = channel.name.toLowerCase().contains(q);
                  final matchAlt =
                      channel.altNames?.any(
                        (a) => a.toLowerCase().contains(q),
                      ) ??
                      false;
                  final matchNetwork =
                      channel.network?.toLowerCase().contains(q) ?? false;
                  if (!matchName && !matchAlt && !matchNetwork) return false;
                }
                // 6️⃣ **NEW** — must have at least one stream
                if (!validStreamIds.contains(channel.id)) return false;

                return true;
              }).toList();

              return AsyncValue.data(filtered);
            },
            loading: () => const AsyncValue.loading(),
            error: (e, st) => AsyncValue.error(e, st),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// Streams for Channel Provider
final streamsForChannelProvider =
    Provider.family<AsyncValue<List<StreamInfo>>, String>((ref, channelId) {
      final streamsAsync = ref.watch(streamsProvider);

      return streamsAsync.when(
        data: (streams) {
          final channelStreams = streams
              .where((stream) => stream.channel == channelId)
              .toList();
          return AsyncValue.data(channelStreams);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    });

// Feeds for Channel Provider
final feedsForChannelProvider = FutureProvider.family<List<Feed>, String>((
  ref,
  channelId,
) async {
  final feeds = await ref.watch(feedsProvider.future);
  return feeds.where((feed) => feed.channel == channelId).toList();
});

// Guides for Channel Provider
final guidesForChannelProvider =
    Provider.family<AsyncValue<List<Guide>>, String>((ref, channelId) {
      final guidesAsync = ref.watch(guidesProvider);

      return guidesAsync.when(
        data: (guides) {
          final channelGuides = guides
              .where((guide) => guide.channel == channelId)
              .toList();
          return AsyncValue.data(channelGuides);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    });

// ==========================================
// 5. COMPLEX VIEWMODELS
// ==========================================

class ChannelDetails {
  final Channel channel;
  final List<Feed> feeds;
  final List<StreamInfo> streams;
  final List<Guide> guides;

  const ChannelDetails({
    required this.channel,
    required this.feeds,
    required this.streams,
    required this.guides,
  });

  // Get best quality stream
  StreamInfo? get bestQualityStream {
    if (streams.isEmpty) return null;

    // Priority order for quality selection
    const qualityPriority = ['1080p', '720p', '480p', '360p', '240p'];

    for (final quality in qualityPriority) {
      final stream = streams.firstWhere(
        (s) => s.quality == quality,
        orElse: () => streams.first,
      );
      if (stream.quality == quality) return stream;
    }

    return streams.first;
  }

  // Get main feed
  Feed? get mainFeed {
    return feeds.firstWhere(
      (feed) => feed.isMain,
      orElse: () => feeds.isNotEmpty ? feeds.first : null as Feed,
    );
  }
}

// Channel Details Provider
final channelDetailsProvider = FutureProvider.family<ChannelDetails, String>((
  ref,
  channelId,
) async {
  final channels = await ref.watch(channelsProvider.future);
  final feeds = await ref.watch(feedsForChannelProvider(channelId).future);

  final streamsAsync = ref.watch(streamsForChannelProvider(channelId));
  final guidesAsync = ref.watch(guidesForChannelProvider(channelId));

  // Handle AsyncValue for streams
  final streams = streamsAsync.when(
    data: (data) => data,
    loading: () => <StreamInfo>[],
    error: (error, stack) => <StreamInfo>[],
  );

  // Handle AsyncValue for guides
  final guides = guidesAsync.when(
    data: (data) => data,
    loading: () => <Guide>[],
    error: (error, stack) => <Guide>[],
  );

  final channel = channels.firstWhere(
    (c) => c.id == channelId,
    orElse: () => throw Exception('Channel not found: $channelId'),
  );

  return ChannelDetails(
    channel: channel,
    feeds: feeds,
    streams: streams,
    guides: guides,
  );
});

// ==========================================
// 6. UI HELPER PROVIDERS
// ==========================================

// Available Countries for Filter
final availableCountriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  final channelsAsync = ref.watch(channelsProvider);

  return channelsAsync.when(
    data: (channels) {
      final countries = channels.map((c) => c.country).toSet().toList()..sort();
      return AsyncValue.data(countries);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Available Categories for Filter
final availableCategoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  final channelsAsync = ref.watch(channelsProvider);

  return channelsAsync.when(
    data: (channels) {
      final categories = <String>{};
      for (final channel in channels) {
        if (channel.categories != null) {
          categories.addAll(channel.categories!);
        }
      }
      final sortedCategories = categories.toList()..sort();
      return AsyncValue.data(sortedCategories);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Statistics Provider
final channelStatisticsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final channelsAsync = ref.watch(channelsProvider);
  final streamsAsync = ref.watch(streamsProvider);

  return channelsAsync.when(
    data: (channels) {
      return streamsAsync.when(
        data: (streams) {
          final stats = {
            'total_channels': channels.length,
            'active_channels': channels.where((c) => c.isActive).length,
            'nsfw_channels': channels.where((c) => c.isNsfw).length,
            'total_streams': streams.length,
            'channels_with_streams': streams
                .map((s) => s.channel)
                .toSet()
                .length,
          };
          return AsyncValue.data(stats);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});
