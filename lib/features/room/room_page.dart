/// 房间主页：正在播放 + 队列 + 聊天 + 点歌，Tab 结构
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/protocol/types.dart';
import '../../core/realtime/connection.dart';
import '../../core/storage/local_store.dart';
import '../player/now_playing_bar.dart';
import '../chat/chat_panel.dart';
import 'search_sheet.dart';

class RoomPage extends StatefulWidget {
  final RoomConnection conn;
  final String me;
  const RoomPage({super.key, required this.conn, required this.me});
  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  RoomSnapshot? _snap;
  final List<ChatMessageEvent> _chat = [];
  StreamSubscription? _evSub;
  ConnStatus _status = ConnStatus.connecting;
  int _online = 0;

  @override
  void initState() {
    super.initState();
    widget.conn.statusStream.listen((s) => mounted
        ? setState(() => _status = s)
        : null);
    _refresh();
    _evSub = widget.conn.roomEventStream.listen(_onEvent);
  }

  Future<void> _refresh() async {
    try {
      final snap = await widget.conn.roomSync();
      if (!mounted) return;
      setState(() {
        _snap = snap;
        _online = snap.members.length;
      });
    } catch (_) {}
  }

  void _onEvent(Map<String, dynamic> msg) {
    final type = msg['type'];
    final data = msg['data'];
    if (!mounted) return;
    setState(() {
      if (type == 'queue.updated') {
        final q = QueueUpdatedEvent.fromJson(data);
        if (_snap != null) {
          _snap = RoomSnapshot(
              term: _snap!.term, seq: _snap!.seq, room: _snap!.room,
              nowPlaying: _snap!.nowPlaying, pending: q.pending,
              items: q.items, members: _snap!.members);
        }
      } else if (type == 'playback.updated') {
        if (_snap != null) {
          _snap = RoomSnapshot(
              term: _snap!.term, seq: _snap!.seq, room: _snap!.room,
              nowPlaying: data['nowPlaying'] == null
                  ? null : NowPlaying.fromJson(data['nowPlaying']),
              pending: _snap!.pending, items: _snap!.items,
              members: _snap!.members);
        }
      } else if (type == 'members.updated') {
        _online = (data['members'] as List? ?? []).length;
      } else if (type == 'chat.message') {
        _chat.add(ChatMessageEvent.fromJson(data));
        if (_chat.length > 200) _chat.removeRange(0, _chat.length - 200);
      }
    });
  }

  Future<void> _openSearch() async {
    final picked = await showModalBottomSheet<SearchTrackItem>(
        context: context, isScrollControlled: true,
        builder: (_) => SearchSheet(conn: widget.conn));
    if (picked != null) {
      try {
        final entry = await widget.conn.queueAddTrack(picked.track);
        LocalStore.addHistory(picked.meta.title, picked.meta.artist);
        widget.conn.chatSend('点了一首《${picked.meta.title}》');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已点 #${entry.id} 《${picked.meta.title}》')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('点歌失败：$e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snap;
    return Scaffold(
      appBar: AppBar(
        title: Text(snap?.room.name ?? '大猫听歌房'),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(child: Row(children: [
                Icon(Icons.circle,
                    size: 10,
                    color: _status == ConnStatus.connected
                        ? Colors.greenAccent : Colors.orangeAccent),
                const SizedBox(width: 4),
                Text('$_online', style: const TextStyle(fontSize: 15)),
              ]))),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSearch,
        icon: const Icon(Icons.search),
        label: const Text('点歌'),
      ),
      body: Column(children: [
        NowPlayingBar(
            nowPlaying: snap?.nowPlaying,
            onVoteSkip: () => widget.conn.voteSkip()),
        Expanded(
          child: ChatPanel(conn: widget.conn, chat: _chat, me: widget.me),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _evSub?.cancel();
    super.dispose();
  }
}
