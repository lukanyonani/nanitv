// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

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
    print('🚀 HomeScreen initState called');
    _pageController = PageController(viewportFraction: 0.8);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cats = ref.read(homeViewModelProvider).categories;
      if (cats.isNotEmpty) {
        print('🍿 Applying initial category filter: ${cats[0]}');
        ref.read(homeViewModelProvider).filterByCategory(cats[0]);
      }
    });
  }

  @override
  void dispose() {
    print('🧹 HomeScreen dispose called');
    _pageController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    print('🌍 Showing country picker');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.8,
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
                    error: (e, _) {
                      print('❌ Country picker error: $e');
                      return Center(
                        child: Text(
                          'Error: $e',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
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
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: countries.length,
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
                                    print(
                                      '🌐 Country selected: ${country.name}',
                                    );
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
    print('🔨 Building HomeScreen UI');
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
                      print('🔍 Search button tapped');
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
                      print('📑 Category tapped: $cat');
                      setState(() => _selectedCategoryIndex = idx);
                      ref.read(homeViewModelProvider).filterByCategory(cat);
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

            // Channel Grid (2 columns!) 🎉
            Expanded(
              child: channelsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) {
                  print('❌ Channel load error: $err');
                  if (err is SocketException) {
                    return _buildNetworkError(
                      () => ref.refresh(homeViewModelProvider),
                    );
                  }
                  return Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                },
                data: (channels) {
                  print('🔎 Displaying ${channels.length} channels in grid');
                  if (channels.isEmpty) {
                    return const Center(
                      child: Text(
                        'No channels in this category',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: channels.length,
                    itemBuilder: (context, index) {
                      final channel = channels[index];
                      print('➡️ Building grid item for: ${channel.name}');
                      return _buildGridChannelCard(
                        channel,
                        index,
                        channels.length,
                      );
                    },
                  );
                },
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
          const Text(
            'No internet connection',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
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

  Widget _buildGridChannelCard(Channel channel, int index, int total) {
    return GestureDetector(
      onTap: () {
        print('▶️ Channel tapped: ${channel.name}');
        Get.to(
          () => ChannelPlayerScreen(
            channelId: channel.id,
            channelName: channel.name,
          ),
        );
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 📸 Logo / Gradient placeholder
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: channel.hasLogo
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CachedNetworkImage(
                          imageUrl: channel.logo!,
                          fit: BoxFit.contain,
                          placeholder: (c, u) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (c, u, e) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 60,
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

            // ℹ️ Info area
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                        fontSize: 12,
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
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${index + 1}/$total',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        print('🔘 Icon button tapped: $icon');
        onTap();
      },
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
