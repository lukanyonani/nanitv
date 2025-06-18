import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/iptv_models.dart';
import '../providers/providers.dart';
// ==========================================
// 5. GUIDES VIEWMODEL
// ==========================================

class GuidesViewModel {
  final Ref _ref;

  GuidesViewModel(this._ref);

  // Core data access
  AsyncValue<List<Guide>> get allGuides => _ref.watch(guidesProvider);

  // Helper methods
  List<Guide> getGuidesForChannel(String channelId) {
    return _ref
        .watch(guidesForChannelProvider(channelId))
        .maybeWhen(data: (guides) => guides, orElse: () => []);
  }

  // Guide analysis
  Map<String, List<Guide>> groupGuidesByChannel() {
    return allGuides.maybeWhen(
      data: (guides) {
        final grouped = <String, List<Guide>>{};
        for (final guide in guides) {
          final channelId = guide.channel ?? 'unknown';
          grouped.putIfAbsent(channelId, () => []).add(guide);
        }
        return grouped;
      },
      orElse: () => {},
    );
  }

  Map<String, int> getSiteDistribution() {
    return allGuides.maybeWhen(
      data: (guides) {
        final distribution = <String, int>{};
        for (final guide in guides) {
          final site = guide.site ?? 'unknown';
          distribution[site] = (distribution[site] ?? 0) + 1;
        }
        return distribution;
      },
      orElse: () => {},
    );
  }

  Map<String, int> getLanguageDistribution() {
    return allGuides.maybeWhen(
      data: (guides) {
        final distribution = <String, int>{};
        for (final guide in guides) {
          final lang = guide.lang ?? 'unknown';
          distribution[lang] = (distribution[lang] ?? 0) + 1;
        }
        return distribution;
      },
      orElse: () => {},
    );
  }

  List<Guide> getGuidesBySite(String site) {
    return allGuides.maybeWhen(
      data: (guides) => guides.where((guide) => guide.site == site).toList(),
      orElse: () => [],
    );
  }

  List<Guide> getGuidesByLanguage(String language) {
    return allGuides.maybeWhen(
      data: (guides) =>
          guides.where((guide) => guide.lang == language).toList(),
      orElse: () => [],
    );
  }

  List<String> get availableSites {
    return allGuides.maybeWhen(
      data: (guides) {
        final sites = guides
            .map((guide) => guide.site ?? 'unknown')
            .toSet()
            .toList();
        return sites..sort();
      },
      orElse: () => [],
    );
  }

  List<String> get availableLanguages {
    return allGuides.maybeWhen(
      data: (guides) {
        final languages = guides
            .map((guide) => guide.lang ?? 'unknown')
            .toSet()
            .toList();
        return languages..sort();
      },
      orElse: () => [],
    );
  }

  int get totalGuidesCount {
    return allGuides.maybeWhen(
      data: (guides) => guides.length,
      orElse: () => 0,
    );
  }

  int get channelsWithGuidesCount {
    final grouped = groupGuidesByChannel();
    return grouped.keys.length;
  }
}

// Provider for GuidesViewModel
final guidesViewModelProvider = Provider<GuidesViewModel>((ref) {
  return GuidesViewModel(ref);
});
