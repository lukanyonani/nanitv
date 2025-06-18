import 'package:flutter/material.dart';
import '../models/iptv_models.dart';
import '../utils/colors.dart';
import '../views/player/player.dart';

class TvCard extends StatefulWidget {
  final Channel channel;

  const TvCard({Key? key, required this.channel}) : super(key: key);

  @override
  _TvCardState createState() => _TvCardState();
}

class _TvCardState extends State<TvCard> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() {
        setState(() => _focused = _focus.hasFocus);
      });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Focus(
        focusNode: _focus,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChannelPlayerScreen(
                  channelId: widget.channel.id,
                  channelName: widget.channel.name,
                ),
              ),
            );
          },
          child: Container(
            width: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused ? AppColors.accent : Colors.transparent,
                width: 4,
              ),
              color: widget.channel.hasLogo ? null : AppColors.overlay,
              image: widget.channel.hasLogo
                  ? DecorationImage(
                      image: NetworkImage(widget.channel.logo!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppColors.overlay,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.channel.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.channel.network != null)
                      Text(
                        widget.channel.network!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
