import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/iptv_models.dart';
import '../../providers/providers.dart';
import '../../utils/colors.dart';
import '../../viewmodels/channel_viewmodel.dart';
import '../../viewmodels/player_viewmodel.dart';

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
      '🎬 [PlayerScreen] -> initState: Starting up for channel "${widget.channelName}"',
    );

    // Keep the screen awake while video is playing
    WakelockPlus.enable();
    print('🔒 [PlayerScreen] -> Wakelock enabled');

    // Reset any previous player state
    _disposePlayer(notify: false);
    ref.read(playerViewModelProvider.notifier).reset();
    print('🧹 [PlayerScreen] -> Cleared old player and reset ViewModel');

    // Lock orientation to landscape for immersive viewing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    print('📐 [PlayerScreen] -> Orientation locked to landscape');

    // Wait until build completes then initialize the first stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFirstStream();
    });
  }

  @override
  void dispose() {
    print('🧹 [PlayerScreen] -> dispose: Cleaning up resources');
    _disposePlayer(notify: false);
    WakelockPlus.disable();
    print('🔓 [PlayerScreen] -> Wakelock disabled');

    // Restore all orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    print('📐 [PlayerScreen] -> Orientation restored');

    super.dispose();
  }

  /// Tear down the player controllers and reset state
  void _disposePlayer({bool notify = true}) {
    print('🧹 [PlayerScreen] -> _disposePlayer: Disposing video controllers');
    _videoPlayerController?.removeListener(_onVideoPlayerChange);
    _videoPlayerController?.pause();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    _videoPlayerController = null;
    _chewieController = null;
    _isPlayerInitialized = false;
    _currentStreamUrl = null;
    _selectedStream = null;
    _retryCount = 0;

    if (notify && mounted) setState(() {});
  }

  bool _isValidStreamUrl(String url) {
    print('🔍 [PlayerScreen] -> Validating URL: $url');
    if (url.isEmpty) {
      print('❌ [PlayerScreen] -> URL is empty');
      return false;
    }
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme ||
          !(uri.scheme.startsWith('http') || uri.scheme.startsWith('rtmp'))) {
        print('❌ [PlayerScreen] -> Invalid scheme: ${uri.scheme}');
        return false;
      }
      print('✅ [PlayerScreen] -> URL looks good');
      return true;
    } catch (e) {
      print('❌ [PlayerScreen] -> URL parse error: $e');
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
    print('🚀 [PlayerScreen] -> Initializing stream: ${stream.url}');
    if (_retryCount >= _maxRetries) {
      print('❌ [PlayerScreen] -> Reached max retries ($_maxRetries)');
      ref
          .read(playerViewModelProvider.notifier)
          .setError('Max retries reached');
      return;
    }

    _disposePlayer(notify: false);
    _retryCount++;
    final vm = ref.read(playerViewModelProvider.notifier);
    vm.setStream(stream);
    vm.setLoading(true);

    try {
      if (!_isValidStreamUrl(stream.url)) {
        throw Exception('Invalid stream URL');
      }

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(stream.url),
        httpHeaders: stream.httpHeaders,
      );
      print('🔧 [PlayerScreen] -> VideoPlayerController created');

      await _videoPlayerController!.initialize().timeout(
        _initializationTimeout,
        onTimeout: () {
          throw Exception('Initialization timed out');
        },
      );
      print('⏳ [PlayerScreen] -> Controller initialized');

      if (_videoPlayerController!.value.hasError) {
        throw Exception(_videoPlayerController!.value.errorDescription);
      }

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
            child: Text(msg, style: TextStyle(color: Colors.white)),
          );
        },
      );
      print('🎮 [PlayerScreen] -> ChewieController configured');

      _videoPlayerController!.addListener(_onVideoPlayerChange);

      setState(() {
        _isPlayerInitialized = true;
        _currentStreamUrl = stream.url;
        _selectedStream = stream;
      });
      vm.setLoading(false);
      vm.setPlaying(true);
      _retryCount = 0;
      print('🎉 [PlayerScreen] -> Stream is now playing');
    } catch (e) {
      final errText = e.toString();
      print('💥 [PlayerScreen] -> Init failed: $errText');
      _disposePlayer();
      final friendly = _getUserFriendlyError(errText);
      vm.setError(friendly);
      vm.setLoading(false);
    }
  }

  void _onVideoPlayerChange() {
    if (_videoPlayerController?.value.hasError == true) {
      final e = _videoPlayerController!.value.errorDescription;
      print('📹 [PlayerScreen] -> Player error: $e');
      ref
          .read(playerViewModelProvider.notifier)
          .setError(_getUserFriendlyError(e ?? 'Unknown error'));
    }
  }

  void _initializeFirstStream() {
    final detailsVm = ref.read(
      channelDetailViewModelProvider(widget.channelId),
    );
    detailsVm.streams.when(
      data: (list) {
        if (list.isNotEmpty) {
          print(
            '🎯 [PlayerScreen] -> First available stream: ${list.first.url}',
          );
          _initializePlayer(list.first);
        } else {
          print('❌ [PlayerScreen] -> No streams found');
        }
      },
      loading: () => print('⏳ [PlayerScreen] -> Loading streams...'),
      error: (e, _) => print('❌ [PlayerScreen] -> Stream load error: $e'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channelDetails = ref
        .watch(channelDetailViewModelProvider(widget.channelId))
        .channelDetails;
    final streams = ref
        .watch(channelDetailViewModelProvider(widget.channelId))
        .streams;
    final state = ref.watch(playerViewModelProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Get.back();
        ref.read(playerViewModelProvider.notifier).reset();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            widget.channelName,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black87,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () => _showChannelInfo(context, channelDetails),
            ),
          ],
        ),
        body: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: _buildVideoPlayer(state),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey.shade900,
                child: streams.when(
                  data: (list) {
                    print('📊 [PlayerScreen] -> ${list.length} streams loaded');
                    return _buildStreamControls(list);
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (e, _) => _buildErrorWidget('Failed to load streams'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(PlayerState state) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text(
              state.error != null
                  ? 'Retrying... ($_retryCount/$_maxRetries)'
                  : 'Loading stream...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 60),
            SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedStream != null
                  ? () {
                      _retryCount = 0;
                      _initializePlayer(_selectedStream!);
                    }
                  : null,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isPlayerInitialized && _chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, color: Colors.white54, size: 80),
          SizedBox(height: 16),
          Text(
            'Select a stream to play',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamControls(List<StreamInfo> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_off, color: Colors.white54, size: 60),
            SizedBox(height: 16),
            Text(
              'No streams available',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stream, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Available Streams (${list.length})',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...list.asMap().entries.map((e) {
            final idx = e.key;
            final info = e.value;
            final isSel = _currentStreamUrl == info.url;
            return Card(
              color: isSel ? Colors.blue.shade800 : Colors.grey.shade800,
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSel ? Colors.blue : Colors.grey.shade700,
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  info.quality ?? 'Unknown',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Icon(
                  isSel
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSel ? Colors.blue : Colors.white54,
                ),
                onTap: () {
                  print(
                    '🎯 [PlayerScreen] -> User selected stream #${idx + 1}',
                  );
                  _retryCount = 0;
                  _initializePlayer(info);
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
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 60),
            SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showChannelInfo(BuildContext ctx, AsyncValue<ChannelDetails> details) {
    showModalBottomSheet(
      context: ctx,
      barrierColor: AppColors.overlay,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (c, ctrl) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: details.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load channel details',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  data: (d) => ListView(
                    controller: ctrl,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      Text(
                        d.channel.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _infoCard('Country', d.channel.country),
                      if (d.channel.network != null)
                        _infoCard('Network', d.channel.network!),
                      if (d.channel.categories != null)
                        _infoCard(
                          'Categories',
                          d.channel.categories!.join(', '),
                        ),
                      _infoCard(
                        'Status',
                        d.channel.isActive ? 'Active' : 'Inactive',
                      ),
                      _infoCard('Streams', '${d.streams.length}'),
                      _infoCard('Feeds', '${d.feeds.length}'),
                      _infoCard('Guides', '${d.guides.length}'),
                      SizedBox(height: 16),
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

  Widget _infoCard(String label, String value) => Card(
    color: AppColors.cardBackground,
    margin: EdgeInsets.symmetric(vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    ),
  );
}
