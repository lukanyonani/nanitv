import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/iptv_models.dart';
import '../providers/providers.dart';

// ==========================================
// 8. FAVORITES VIEWMODEL
// ==========================================

class FavoritesViewModel extends StateNotifier<List<String>> {
  final Ref _ref;

  FavoritesViewModel(this._ref) : super([]);

  // Add/Remove favorites
  void addFavorite(String channelId) {
    if (!state.contains(channelId)) {
      state = [...state, channelId];
      _saveFavorites();
    }
  }

  void removeFavorite(String channelId) {
    state = state.where((id) => id != channelId).toList();
    _saveFavorites();
  }

  void toggleFavorite(String channelId) {
    if (isFavorite(channelId)) {
      removeFavorite(channelId);
    } else {
      addFavorite(channelId);
    }
  }

  bool isFavorite(String channelId) {
    return state.contains(channelId);
  }

  void clearFavorites() {
    state = [];
    _saveFavorites();
  }

  // Get favorite channels
  AsyncValue<List<Channel>> get favoriteChannels {
    final channelsAsync = _ref.watch(channelsProvider);

    return channelsAsync.when(
      data: (channels) {
        final favorites = channels
            .where((channel) => state.contains(channel.id))
            .toList();
        return AsyncValue.data(favorites);
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    );
  }

  // Statistics
  int get favoritesCount => state.length;

  bool get hasFavorites => state.isNotEmpty;

  // Persistence methods (implement based on your storage preference)
  void _saveFavorites() {
    // TODO: Save to SharedPreferences or other persistent storage
    // Example: SharedPreferences.getInstance().then((prefs) =>
    //   prefs.setStringList('favorites', state));
  }

  void loadFavorites() {
    // TODO: Load from SharedPreferences or other persistent storage
    // Example: SharedPreferences.getInstance().then((prefs) {
    //   final favorites = prefs.getStringList('favorites') ?? [];
    //   state = favorites;
    // });
  }
}

// Provider for FavoritesViewModel
final favoritesViewModelProvider =
    StateNotifierProvider<FavoritesViewModel, List<String>>((ref) {
      final viewModel = FavoritesViewModel(ref);
      viewModel.loadFavorites(); // Load saved favorites on initialization
      return viewModel;
    });
