// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/iptv_models.dart';
import '../../providers/providers.dart';
import '../../utils/colors.dart';
import '../../viewmodels/search_viewmodels.dart';
import '../player/player.dart';

class SearchScreen extends ConsumerStatefulWidget {
  static const routeName = '/search';
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchViewModelProvider);
    final vm = ref.read(searchViewModelProvider.notifier);

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
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Search Channels',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Search Field ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type channel name…',
                  hintStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: vm.search,
              ),
            ),

            const SizedBox(height: 12),

            // ─── Results ─────────────────────────────────────────────
            Expanded(
              child: state.isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                  ? Center(
                      child: Text(
                        'Error: ${state.error}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    )
                  : state.query.isEmpty
                  ? const Center(
                      child: Text(
                        'Start typing to search channels',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : _buildChannelListWithStreams(state.channelResults),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelListWithStreams(List<Channel> channels) {
    // watch the global streams list
    final streamsAsync = ref.watch(streamsProvider);

    return streamsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          'Error loading streams: $err',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
      data: (allStreams) {
        // build a set of channel IDs that have at least one stream
        final validIds = allStreams.map((s) => s.channel).toSet();

        // only keep channels with streams
        final filtered = channels
            .where((c) => validIds.contains(c.id))
            .toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              'No channels with streams found',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white10),
          itemBuilder: (context, i) {
            final channel = filtered[i];
            return ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChannelPlayerScreen(
                    channelId: channel.id,
                    channelName: channel.name,
                  ),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 4,
              ),
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: channel.hasLogo
                    ? CachedNetworkImage(
                        imageUrl: channel.logo!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                        ),
                      )
                    : Icon(Icons.tv, color: Colors.white54, size: 32),
              ),
              title: Text(
                channel.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                channel.country.toUpperCase(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            );
          },
        );
      },
    );
  }
}
