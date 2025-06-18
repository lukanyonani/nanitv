import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/iptv_models.dart';

// ==========================================
// 4. PLAYER VIEWMODEL
// ==========================================

class PlayerState {
  final StreamInfo? currentStream;
  final bool isPlaying;
  final bool isLoading;
  final String? error;
  final Duration position;
  final Duration duration;
  final double volume;

  const PlayerState({
    this.currentStream,
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
  });

  PlayerState copyWith({
    StreamInfo? currentStream,
    bool? isPlaying,
    bool? isLoading,
    String? error,
    Duration? position,
    Duration? duration,
    double? volume,
  }) {
    return PlayerState(
      currentStream: currentStream ?? this.currentStream,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
    );
  }
}

class PlayerViewModel extends StateNotifier<PlayerState> {
  PlayerViewModel() : super(const PlayerState());

  void setStream(StreamInfo stream) {
    state = state.copyWith(currentStream: stream, isLoading: true, error: null);
  }

  void setPlaying(bool isPlaying) {
    state = state.copyWith(isPlaying: isPlaying);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void updatePosition(Duration position) {
    state = state.copyWith(position: position);
  }

  void updateDuration(Duration duration) {
    state = state.copyWith(duration: duration);
  }

  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  void reset() {
    state = const PlayerState();
  }

  // Convenience getters
  bool get hasStream => state.currentStream != null;
  bool get hasError => state.error != null;
  String get streamUrl => state.currentStream?.url ?? '';
  Map<String, String> get streamHeaders =>
      state.currentStream?.httpHeaders ?? {};

  double get progress {
    if (state.duration.inMilliseconds == 0) return 0.0;
    return state.position.inMilliseconds / state.duration.inMilliseconds;
  }
}

// Provider for PlayerViewModel
final playerViewModelProvider =
    StateNotifierProvider<PlayerViewModel, PlayerState>((ref) {
      return PlayerViewModel();
    });

// ==========================================
// 5. PLAYLIST VIEWMODEL
// ==========================================

class PlaylistViewModel extends StateNotifier<List<StreamInfo>> {
  PlaylistViewModel() : super([]);

  void addToPlaylist(StreamInfo stream) {
    state = [...state, stream];
  }

  void removeFromPlaylist(StreamInfo stream) {
    state = state.where((s) => s.id != stream.id).toList();
  }

  void clearPlaylist() {
    state = [];
  }
}

// Provider for PlaylistViewModel
final playlistViewModelProvider =
    StateNotifierProvider<PlaylistViewModel, List<StreamInfo>>((ref) {
      return PlaylistViewModel();
    });
