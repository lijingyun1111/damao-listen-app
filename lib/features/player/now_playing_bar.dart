/// 底部正在播放条：封面/歌名/进度，点击可展开投票切歌
library;

import 'package:flutter/material.dart';
import '../../core/protocol/types.dart';

class NowPlayingBar extends StatelessWidget {
  final NowPlaying? nowPlaying;
  final VoidCallback onVoteSkip;
  const NowPlayingBar({super.key, this.nowPlaying, required this.onVoteSkip});

  @override
  Widget build(BuildContext context) {
    final np = nowPlaying;
    final entry = np?.entry;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08)))),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (entry?.meta.coverUrl != null && entry!.meta.coverUrl!.isNotEmpty)
              ? Image.network(entry.meta.coverUrl!,
                  width: 52, height: 52, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry?.meta.title ?? '暂无播放',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(entry?.meta.artist ?? '等待下一首歌…',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.white54)),
          ]),
        ),
        if (entry != null)
          IconButton(
              tooltip: '投票切歌',
              onPressed: onVoteSkip,
              icon: const Icon(Icons.skip_next)),
      ]),
    );
  }

  Widget _placeholder() => Container(
      width: 52, height: 52,
      color: Colors.white10,
      child: const Icon(Icons.album, color: Colors.white24));
}
