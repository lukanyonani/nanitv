import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/iptv_models.dart';
import '../providers/providers.dart';

// ==========================================
// 3. STREAMS VIEWMODEL
// ==========================================

class StreamsViewModel {
  final Ref _ref;

  StreamsViewModel(this._ref);

  // Core data access
  AsyncValue<List<StreamInfo>> get allStreams => _ref.watch(streamsProvider);
  AsyncValue<Map<String, int>> get statistics =>
      _ref.watch(channelStatisticsProvider);

  // Helper methods
  List<StreamInfo> getStreamsForChannel(String channelId) {
    return _ref
        .watch(streamsForChannelProvider(channelId))
        .maybeWhen(data: (streams) => streams, orElse: () => []);
  }

  // Stream analysis
  Map<String, List<StreamInfo>> groupStreamsByChannel() {
    return allStreams.maybeWhen(
      data: (streams) {
        final grouped = <String, List<StreamInfo>>{};
        for (final stream in streams) {
          final channelId = stream.channel ?? 'unknown';
          grouped.putIfAbsent(channelId, () => []).add(stream);
        }
        return grouped;
      },
      orElse: () => {},
    );
  }

  Map<String, int> getQualityDistribution() {
    return allStreams.maybeWhen(
      data: (streams) {
        final distribution = <String, int>{};
        for (final stream in streams) {
          final quality = stream.quality ?? 'unknown';
          distribution[quality] = (distribution[quality] ?? 0) + 1;
        }
        return distribution;
      },
      orElse: () => {},
    );
  }

  List<String> getChannelsWithMultipleStreams() {
    final grouped = groupStreamsByChannel();
    return grouped.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => entry.key)
        .toList();
  }

  int get totalStreamsCount {
    return allStreams.maybeWhen(
      data: (streams) => streams.length,
      orElse: () => 0,
    );
  }

  int get channelsWithStreamsCount {
    return statistics.maybeWhen(
      data: (stats) => stats['channels_with_streams'] ?? 0,
      orElse: () => 0,
    );
  }
}

// Provider for StreamsViewModel
final streamsViewModelProvider = Provider<StreamsViewModel>((ref) {
  return StreamsViewModel(ref);
});
