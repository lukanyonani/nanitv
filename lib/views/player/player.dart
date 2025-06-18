import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/iptv_models.dart';
import '../../providers/providers.dart';
import '../../utils/colors.dart';
import '../../viewmodels/channel_viewmodel.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../home/home_page.dart';

class ChannelPlayerScreen extends ConsumerStatefulWidget {
  final String channelId;
  final String channelName;

  const ChannelPlayerScreen({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  ConsumerState<ChannelPlayerScreen> createState() =>
      _ChannelPlayerScreenState();
}

class _ChannelPlayerScreenState extends ConsumerState<ChannelPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isPlayerInitialized = false;
  String? _currentStreamUrl;
  StreamInfo? _selectedStream;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _initializationTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    print(
      '🎬 [PlayerScreen] Initializing player screen for channel: ${widget.channelName}',
    );

    // Ensure a clean slate by disposing any existing player
    _disposePlayer(notify: false);

    // Reset the PlayerViewModel to clear any stale state
    ref.read(playerViewModelProvider.notifier).reset();

    // Lock orientation to landscape for better viewing experience
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    // Initialize the player with the first available stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFirstStream();
    });
  }

  @override
  void dispose() {
    print('🧹 [PlayerScreen] Disposing player screen');
    _disposePlayer(notify: false);

    // Reset orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  /// Completely tears down any existing player so a fresh one can be built.
  void _disposePlayer({bool notify = true}) {
    print('🧹 [PlayerScreen] Disposing player resources');
    // Remove listener if present
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(_onVideoPlayerChange);
    }

    // Pause and dispose controllers
    _videoPlayerController?.pause();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    // Clear fields
    _chewieController = null;
    _videoPlayerController = null;
    _isPlayerInitialized = false;
    _currentStreamUrl = null;
    _selectedStream = null;
    _retryCount = 0;

    // Notify UI if requested and mounted
    if (notify && mounted) {
      setState(() {});
    }
  }

  bool _isValidStreamUrl(String url) {
    print('🔍 [PlayerScreen] Validating stream URL: $url');
    if (url.isEmpty) {
      print('❌ [PlayerScreen] URL is empty');
      return false;
    }

    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme ||
          (!uri.scheme.startsWith('http') && !uri.scheme.startsWith('rtmp'))) {
        print('❌ [PlayerScreen] Invalid URL scheme: ${uri.scheme}');
        return false;
      }
      print('✅ [PlayerScreen] URL validation passed');
      return true;
    } catch (e) {
      print('❌ [PlayerScreen] URL parsing failed: $e');
      return false;
    }
  }

  String _getUserFriendlyError(String error) {
    if (error.toLowerCase().contains('timeout')) {
      return 'Connection timeout';
    } else if (error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('http')) {
      return 'Network error';
    } else if (error.toLowerCase().contains('codec') ||
        error.toLowerCase().contains('format')) {
      return 'Unsupported format';
    } else if (error.toLowerCase().contains('invalid')) {
      return 'Invalid stream';
    } else if (error.toLowerCase().contains('unavailable')) {
      return 'Stream unavailable';
    } else {
      return 'Playback error';
    }
  }

  Future<void> _initializePlayer(StreamInfo stream) async {
    print('🚀 [PlayerScreen] Initializing stream: ${stream.url}');
    if (_retryCount >= _maxRetries) {
      print('❌ [PlayerScreen] Max retries reached ($_maxRetries)');
      ref
          .read(playerViewModelProvider.notifier)
          .setError('Max retries reached');
      return;
    }

    _disposePlayer(notify: false);
    _retryCount++;

    final playerViewModel = ref.read(playerViewModelProvider.notifier);
    playerViewModel.setStream(stream);
    playerViewModel.setLoading(true);

    try {
      if (!_isValidStreamUrl(stream.url)) {
        throw Exception('Invalid stream URL: ${stream.url}');
      }

      print('🔧 Creating VideoPlayerController...');
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(stream.url),
        httpHeaders: stream.httpHeaders,
      );

      print('⏳ Initializing (timeout ${_initializationTimeout.inSeconds}s)...');
      await _videoPlayerController!.initialize().timeout(
        _initializationTimeout,
        onTimeout: () {
          throw Exception('Initialization timed out');
        },
      );

      if (_videoPlayerController!.value.hasError) {
        throw Exception(_videoPlayerController!.value.errorDescription);
      }

      print('🎮 Creating ChewieController...');
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        placeholder: Container(color: Colors.black),
        errorBuilder: (ctx, err) {
          final msg = _getUserFriendlyError(err);
          return Center(
            child: Text(msg, style: const TextStyle(color: Colors.white)),
          );
        },
      );

      _videoPlayerController!.addListener(_onVideoPlayerChange);

      setState(() {
        _isPlayerInitialized = true;
        _currentStreamUrl = stream.url;
        _selectedStream = stream;
      });
      playerViewModel.setLoading(false);
      playerViewModel.setPlaying(true);
      _retryCount = 0; // Reset retry count on success
      print('🎉 Player ready!');
    } catch (e, st) {
      final errorText = e.toString();
      print('💥 Initialization failed: $errorText');
      print(st);

      if (errorText.contains('Response code: 404')) {
        print('🔍 [PlayerScreen] Stream returned 404—trying next stream');
        _disposePlayer(notify: false);
        _tryNextStream();
        return;
      }

      _disposePlayer();
      final friendly = _getUserFriendlyError(errorText);
      playerViewModel.setError(friendly);
      playerViewModel.setLoading(false);
    }
  }

  void _onVideoPlayerChange() {
    if (_videoPlayerController?.value.hasError == true) {
      final error = _videoPlayerController!.value.errorDescription;
      print('📹 [PlayerScreen] Video player error detected: $error');
      final playerViewModel = ref.read(playerViewModelProvider.notifier);
      playerViewModel.setError(_getUserFriendlyError(error ?? 'Unknown error'));
    }
  }

  void _initializeFirstStream() {
    final channelDetailViewModel = ref.read(
      channelDetailViewModelProvider(widget.channelId),
    );

    channelDetailViewModel.streams.when(
      data: (streamList) {
        if (streamList.isNotEmpty) {
          print(
            '🎯 [PlayerScreen] Initializing first stream: ${streamList.first.url}',
          );
          _initializePlayer(streamList.first);
        } else {
          print('❌ [PlayerScreen] No streams available for initialization');
        }
      },
      loading: () => print('⏳ [PlayerScreen] Waiting for streams to load...'),
      error: (error, stack) =>
          print('❌ [PlayerScreen] Error loading streams: $error'),
    );
  }

  void _tryNextStream() {
    print('🔄 [PlayerScreen] Trying to find next available stream...');
    final channelDetailViewModel = ref.read(
      channelDetailViewModelProvider(widget.channelId),
    );

    channelDetailViewModel.streams.when(
      data: (streamList) {
        if (streamList.isEmpty) {
          print('❌ [PlayerScreen] No streams available');
          return;
        }

        int currentIndex = -1;
        if (_selectedStream != null) {
          currentIndex = streamList.indexWhere(
            (s) => s.url == _selectedStream!.url,
          );
        }

        int nextIndex = (currentIndex + 1) % streamList.length;
        if (nextIndex == currentIndex) {
          print('❌ [PlayerScreen] No other streams available to try');
          return;
        }

        final nextStream = streamList[nextIndex];
        print('🎯 [PlayerScreen] Trying next stream: ${nextStream.url}');
        _initializePlayer(nextStream);
      },
      loading: () => print('⏳ [PlayerScreen] Streams still loading...'),
      error: (error, stack) =>
          print('❌ [PlayerScreen] Error loading streams: $error'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channelDetailViewModel = ref.watch(
      channelDetailViewModelProvider(widget.channelId),
    );
    final channelDetails = channelDetailViewModel.channelDetails;
    final streams = channelDetailViewModel.streams;
    final playerState = ref.watch(playerViewModelProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.back();
          ref
              .read(playerViewModelProvider.notifier)
              .reset(); // Reset on navigation
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            widget.channelName,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black87,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showChannelInfo(context, channelDetails),
            ),
            if (_selectedStream != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  print('🔄 [PlayerScreen] Manual refresh requested');
                  _retryCount = 0;
                  _initializePlayer(_selectedStream!);
                },
              ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: _tryNextStream,
              tooltip: 'Try Next Stream',
            ),
          ],
        ),
        body: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: _buildVideoPlayer(playerState),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey.shade900,
                child: streams.when(
                  data: (streamList) {
                    print(
                      '📊 [PlayerScreen] Loaded ${streamList.length} streams',
                    );
                    return _buildStreamControls(streamList);
                  },
                  loading: () {
                    print('⏳ [PlayerScreen] Loading streams...');
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  error: (error, stack) {
                    print('❌ [PlayerScreen] Error loading streams: $error');
                    return _buildErrorWidget('Failed to load streams');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(PlayerState playerState) {
    if (playerState.isLoading) {
      print('⏳ [PlayerScreen] Showing loading state');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              _retryCount > 0
                  ? 'Loading... (${_retryCount}/$_maxRetries)'
                  : 'Loading stream...',
              style: const TextStyle(color: Colors.white),
            ),
            if (_selectedStream != null) ...[
              const SizedBox(height: 8),
              Text(
                'Quality: ${_selectedStream!.quality ?? 'Unknown'}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
      );
    }

    if (playerState.error != null) {
      print('❌ [PlayerScreen] Showing error state: ${playerState.error}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              playerState.error!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _selectedStream != null
                      ? () {
                          print('🔄 [PlayerScreen] Manual retry requested');
                          _retryCount = 0;
                          _initializePlayer(_selectedStream!);
                        }
                      : null,
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _tryNextStream,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Next Stream'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_isPlayerInitialized && _chewieController != null) {
      print('▶️ [PlayerScreen] Showing initialized player');
      return Chewie(controller: _chewieController!);
    }

    print('💤 [PlayerScreen] Showing default state');
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, color: Colors.white54, size: 80),
          SizedBox(height: 16),
          Text(
            'Select a stream to start playing',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamControls(List<StreamInfo> streamList) {
    if (streamList.isEmpty) {
      print('📺 [PlayerScreen] No streams available');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_off, color: Colors.white54, size: 60),
            SizedBox(height: 16),
            Text(
              'No streams available for this channel',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final qualityGroups = <String, List<StreamInfo>>{};
    for (final stream in streamList) {
      final quality = stream.quality ?? 'Unknown';
      qualityGroups.putIfAbsent(quality, () => []).add(stream);
    }

    print(
      '📊 [PlayerScreen] Stream quality groups: ${qualityGroups.keys.toList()}',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stream, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Available Streams (${streamList.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (qualityGroups.length > 1) ...[
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: qualityGroups.keys.map((quality) {
                  final isSelected = _selectedStream?.quality == quality;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        '$quality (${qualityGroups[quality]!.length})',
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected && qualityGroups[quality]!.isNotEmpty) {
                          print(
                            '🎯 [PlayerScreen] Quality filter selected: $quality',
                          );
                          _initializePlayer(qualityGroups[quality]!.first);
                        }
                      },
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.grey.shade700,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...streamList.asMap().entries.map((entry) {
            final index = entry.key;
            final stream = entry.value;
            final isSelected = _currentStreamUrl == stream.url;
            final isPlaying = isSelected && _isPlayerInitialized;

            return Card(
              color: isSelected ? Colors.blue.shade800 : Colors.grey.shade800,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? Colors.blue
                      : Colors.grey.shade600,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  stream.quality ?? 'Unknown Quality',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPlaying)
                      const Icon(
                        Icons.play_arrow,
                        color: Colors.green,
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blue : Colors.white54,
                    ),
                  ],
                ),
                onTap: () {
                  print('🎯 [PlayerScreen] Stream selected: ${stream.url}');
                  print('📊 [PlayerScreen] Stream quality: ${stream.quality}');
                  _retryCount = 0;
                  _initializePlayer(stream);
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showChannelInfo(
    BuildContext context,
    AsyncValue<ChannelDetails> channelDetails,
  ) {
    showModalBottomSheet(
      context: context,
      barrierColor: AppColors.overlay, // semi‐opaque dimmer
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // let our Container define everything
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface, // dark panel
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // accent‐colored drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: channelDetails.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                  error: (e, st) => Center(
                    child: Text(
                      'Failed to load channel details',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  data: (details) => ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      Text(
                        details.channel.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info rows in Cards
                      _infoCard('Country', details.channel.country),
                      if (details.channel.network != null)
                        _infoCard('Network', details.channel.network!),
                      if (details.channel.categories != null)
                        _infoCard(
                          'Categories',
                          details.channel.categories!.join(', '),
                        ),
                      _infoCard(
                        'Status',
                        details.channel.isActive ? 'Active' : 'Inactive',
                      ),
                      _infoCard('Streams', '${details.streams.length}'),
                      _infoCard('Feeds', '${details.feeds.length}'),
                      _infoCard('Guides', '${details.guides.length}'),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A little helper to render a label/value pair inside a Card.
  Widget _infoCard(String label, String value) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
