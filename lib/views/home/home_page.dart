// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../models/iptv_models.dart';
import '../../providers/providers.dart';
import '../../viewmodels/channel_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../player/player.dart';
import '../../utils/colors.dart';
import '../search/search_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/';
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  int _selectedCategoryIndex = 0;
  String? _chosenCountryCode;
  String? _chosenCountryName;
  String? _chosenCountryFlag;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cats = ref.read(homeViewModelProvider).categories;
      if (cats.isNotEmpty) {
        ref.read(homeViewModelProvider).filterByCategory(cats[0]);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // allow full-screen drag but we’ll bound it below
      backgroundColor:
          Colors.transparent, // transparent so our Container’s radius shows
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4, // start at 40% of screen height
          minChildSize: 0.2, // you can drag down to 20%
          maxChildSize: 0.8, // you can drag up to 80%
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Consumer(
                builder: (context, ref, _) {
                  final countriesAsync = ref.watch(countriesProvider);
                  return countriesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    data: (countries) {
                      countries.sort((a, b) => a.name.compareTo(b.name));
                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'Choose a Country',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              controller:
                                  scrollController, // IMPORTANT: hook up the controller
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: countries.length, // no “+1”
                              itemBuilder: (context, idx) {
                                final country = countries[idx];
                                return ListTile(
                                  leading: country.flag != null
                                      ? Text(
                                          country.flag!,
                                          style: const TextStyle(fontSize: 24),
                                        )
                                      : const Icon(
                                          Icons.flag,
                                          color: AppColors.textSecondary,
                                        ),
                                  title: Text(
                                    country.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    setState(() {
                                      _chosenCountryCode = country.code;
                                      _chosenCountryName = country.name;
                                      _chosenCountryFlag = country.flag;
                                    });
                                    ref
                                        .read(homeViewModelProvider)
                                        .filterByCountry(country.code);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(homeViewModelProvider);
    final categories = vm.categories;
    final channelsAsync = vm.filteredChannels;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  _buildIconButton(
                    Icons.search,
                    onTap: () {
                      Get.to(() => SearchScreen());
                    },
                  ),
                  Expanded(
                    child: _chosenCountryCode == null
                        ? const Text(
                            'All Channels',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_chosenCountryFlag != null)
                                Text(
                                  _chosenCountryFlag!,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                _chosenCountryName!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                  _buildIconButton(Icons.more_vert, onTap: _showCountryPicker),
                ],
              ),
            ),

            // Category Tabs
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final isSel = idx == _selectedCategoryIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategoryIndex = idx);
                      ref.read(homeViewModelProvider).filterByCategory(cat);
                      _pageController.jumpToPage(0);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              color: isSel ? AppColors.accent : Colors.white70,
                              fontSize: isSel ? 18 : 16,
                              fontWeight: isSel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            child: Text(cat.toUpperCase()),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 3,
                            width: isSel ? 24 : 0,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Channel Carousel
            Expanded(
              child: Center(
                child: SizedBox(
                  height: 450,
                  child: channelsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) {
                      // Detect network lookup failures
                      if (err is SocketException) {
                        return _buildNetworkError(() {
                          // force Riverpod to re-fetch your filtered channels
                          ref.refresh(homeViewModelProvider);
                        });
                      }
                      // fallback for other errors
                      return Center(
                        child: Text(
                          'Error: $err',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    },
                    data: (channels) {
                      if (channels.isEmpty) {
                        return const Center(
                          child: Text(
                            'No channels in this category',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      return PageView.builder(
                        controller: _pageController,
                        onPageChanged: (idx) =>
                            setState(() => _currentPage = idx),
                        itemCount: channels.length,
                        itemBuilder: (context, index) {
                          final channel = channels[index];
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double value = 0;
                              if (_pageController.position.haveDimensions) {
                                value = index - (_pageController.page ?? 0);
                                value = (value * 0.038).clamp(-1, 1);
                              }
                              return Transform.rotate(
                                angle: value,
                                child: Transform.scale(
                                  scale: 1 - (value.abs() * 0.15),
                                  child: _buildCarouselChannelCard(
                                    channel,
                                    index,
                                    channels.length,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkError(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: Colors.white54, size: 80),
          const SizedBox(height: 16),
          Text(
            'No internet connection',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your network and try again.',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselChannelCard(Channel channel, int index, int total) {
    final channelDetailViewModel = ref.watch(
      channelDetailViewModelProvider(channel.id),
    );
    final streams = channelDetailViewModel.streams;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChannelPlayerScreen(
            channelId: channel.id,
            channelName: channel.name,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1A1F2E),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or gradient
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: channel.hasLogo
                    ? CachedNetworkImage(
                        imageUrl: channel.logo!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          //color: const Color.fromARGB(255, 29, 36, 58),
                          child: const Center(
                            child: Icon(
                              size: 120,
                              Icons.broken_image,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2A3A5C), Color(0xFF1A2B4C)],
                          ),
                        ),
                      ),
              ),
            ),

            // Info area
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      channel.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (channel.primaryCategory != null)
                      Text(
                        channel.primaryCategory!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.live_tv,
                          color: index == _currentPage
                              ? AppColors.accent
                              : Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${index + 1}/$total Channel',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        //Loaded ${streamList.length} streams
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          color: index == _currentPage
                              ? AppColors.accent
                              : Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${streams.value?.length ?? 0} Stream',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        //Loaded ${streamList.length} streams
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: icon == Icons.more_vert
            ? Container(
                width: 18,
                height: 18,
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    4,
                    (_) => Container(
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              )
            : Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}
