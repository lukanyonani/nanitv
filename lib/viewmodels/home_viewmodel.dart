import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/iptv_models.dart';
import '../providers/providers.dart'; // make sure this exports channelFiltersProvider & filteredChannelsProvider

class HomeViewModel {
  HomeViewModel(this._ref);
  final Ref _ref;

  /// All categories (pulled from your availableCategoriesProvider)
  List<String> get categories {
    final snapshot = _ref.watch(availableCategoriesProvider);
    return snapshot.maybeWhen(data: (list) => list, orElse: () => []);
  }

  /// Channels filtered by both country & category
  AsyncValue<List<Channel>> get filteredChannels =>
      _ref.watch(filteredChannelsProvider);

  /// User tapped a category tab
  void filterByCategory(String category) {
    _ref.read(channelFiltersProvider.notifier).updateCategoryFilter(category);
  }

  /// User picked a country from the picker
  void filterByCountry(String countryCode) {
    _ref.read(channelFiltersProvider.notifier).updateCountryFilter(countryCode);
  }
}

/// Expose to Riverpod
final homeViewModelProvider = Provider<HomeViewModel>((ref) {
  return HomeViewModel(ref);
});
