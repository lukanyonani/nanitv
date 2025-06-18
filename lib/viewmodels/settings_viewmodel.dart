import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ==========================================
/// 9. SETTINGS VIEWMODEL
/// ==========================================

class AppSettings {
  final bool darkMode;
  final String preferredLanguage;
  final String preferredQuality;
  final bool autoPlay;
  final bool showNsfwContent;
  final bool useExternalPlayer;
  final double playbackSpeed;
  final int bufferSize;

  const AppSettings({
    this.darkMode = false,
    this.preferredLanguage = 'en',
    this.preferredQuality = '720p',
    this.autoPlay = false,
    this.showNsfwContent = false,
    this.useExternalPlayer = false,
    this.playbackSpeed = 1.0,
    this.bufferSize = 5000,
  });

  AppSettings copyWith({
    bool? darkMode,
    String? preferredLanguage,
    String? preferredQuality,
    bool? autoPlay,
    bool? showNsfwContent,
    bool? useExternalPlayer,
    double? playbackSpeed,
    int? bufferSize,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredQuality: preferredQuality ?? this.preferredQuality,
      autoPlay: autoPlay ?? this.autoPlay,
      showNsfwContent: showNsfwContent ?? this.showNsfwContent,
      useExternalPlayer: useExternalPlayer ?? this.useExternalPlayer,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      bufferSize: bufferSize ?? this.bufferSize,
    );
  }
}

class SettingsViewModel extends StateNotifier<AppSettings> {
  SettingsViewModel() : super(const AppSettings()) {
    _loadSettings();
  }

  // Theme settings
  void toggleDarkMode() {
    state = state.copyWith(darkMode: !state.darkMode);
    _saveSettings();
  }

  void setDarkMode(bool enabled) {
    state = state.copyWith(darkMode: enabled);
    _saveSettings();
  }

  // Language settings
  void setPreferredLanguage(String language) {
    state = state.copyWith(preferredLanguage: language);
    _saveSettings();
  }

  // Quality settings
  void setPreferredQuality(String quality) {
    state = state.copyWith(preferredQuality: quality);
    _saveSettings();
  }

  List<String> get availableQualities => [
    '1080p',
    '720p',
    '480p',
    '360p',
    '240p',
  ];

  // Playback settings
  void toggleAutoPlay() {
    state = state.copyWith(autoPlay: !state.autoPlay);
    _saveSettings();
  }

  void setAutoPlay(bool enabled) {
    state = state.copyWith(autoPlay: enabled);
    _saveSettings();
  }

  void toggleNsfwContent() {
    state = state.copyWith(showNsfwContent: !state.showNsfwContent);
    _saveSettings();
  }

  void setShowNsfwContent(bool enabled) {
    state = state.copyWith(showNsfwContent: enabled);
    _saveSettings();
  }

  void toggleExternalPlayer() {
    state = state.copyWith(useExternalPlayer: !state.useExternalPlayer);
    _saveSettings();
  }

  void setUseExternalPlayer(bool enabled) {
    state = state.copyWith(useExternalPlayer: enabled);
    _saveSettings();
  }

  void setPlaybackSpeed(double speed) {
    state = state.copyWith(playbackSpeed: speed.clamp(0.25, 2.0));
    _saveSettings();
  }

  List<double> get availablePlaybackSpeeds => [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  void setBufferSize(int size) {
    state = state.copyWith(bufferSize: size.clamp(1000, 30000));
    _saveSettings();
  }

  // Reset settings
  void resetToDefaults() {
    state = const AppSettings();
    _saveSettings();
  }

  // Persistence methods
  void _saveSettings() {
    // TODO: Save to SharedPreferences or other persistent storage
    // Example implementation:
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.setBool('darkMode', state.darkMode);
    //   prefs.setString('preferredLanguage', state.preferredLanguage);
    //   prefs.setString('preferredQuality', state.preferredQuality);
    //   prefs.setBool('autoPlay', state.autoPlay);
    //   prefs.setBool('showNsfwContent', state.showNsfwContent);
    //   prefs.setBool('useExternalPlayer', state.useExternalPlayer);
    //   prefs.setDouble('playbackSpeed', state.playbackSpeed);
    //   prefs.setInt('bufferSize', state.bufferSize);
    // });
  }

  void _loadSettings() {
    // TODO: Load from SharedPreferences or other persistent storage
    // Example implementation:
    // SharedPreferences.getInstance().then((prefs) {
    //   state = AppSettings(
    //     darkMode: prefs.getBool('darkMode') ?? false,
    //     preferredLanguage: prefs.getString('preferredLanguage') ?? 'en',
    //     preferredQuality: prefs.getString('preferredQuality') ?? '720p',
    //     autoPlay: prefs.getBool('autoPlay') ?? false,
    //     showNsfwContent: prefs.getBool('showNsfwContent') ?? false,
    //     useExternalPlayer: prefs.getBool('useExternalPlayer') ?? false,
    //     playbackSpeed: prefs.getDouble('playbackSpeed') ?? 1.0,
    //     bufferSize: prefs.getInt('bufferSize') ?? 5000,
    //   );
    // });
  }
}

// Provider for SettingsViewModel
final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, AppSettings>((ref) {
      return SettingsViewModel();
    });
