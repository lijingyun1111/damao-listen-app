/// 聊天面板：消息列表 + 输入框 + 队列列表切换
library;

import 'package:flutter/material.dart';
import '../../core/protocol/types.dart';
import '../../core/realtime/connection.dart';

class ChatPanel extends StatefulWidget {
  final RoomConnection conn;
  final List<ChatMessageEvent> chat;
  final String me;
  final List<Entry>? queue;
  const ChatPanel({super.key, required this.conn, required this.chat, required this.me, this.queue});
  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _input = TextEditingController();
  final _scroll = ScrollController();

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    try {
      await widget.conn.chatSend(text);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    return Column(children: [
      TabBar(controller: _tab, tabs: const [
        Tab(text: '聊天'),
        Tab(text: '队列'),
      ]),
      Expanded(
        child: TabBarView(controller: _tab, children: [
          // 聊天
          Column(children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: chat.length,
                itemBuilder: (_, i) {
                  final m = chat[chat.length - 1 - i];
                  final mine = m.member.name == widget.me;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (mine) const Spacer(),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: mine
                                  ? const Color(0xFF4A6CF7).withOpacity(0.35)
                                  : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.member.name,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: mine
                                              ? Colors.lightBlueAccent
                                              : Colors.white38)),
                                  Text(m.content,
                                      style: const TextStyle(fontSize: 15)),
                                ]),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                          hintText: '说点什么…',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24))),
                    ),
                  ),
                  IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                ]),
              ),
            ),
          ]),
          // 队列
          Builder(builder: (_) {
            // 从父级快照拿不到就空态；队列事件会驱动重建
            final q = widget.queue;
            if (q == null || q.isEmpty) {
              return const Center(child: Text('队列空空，快点点歌'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: q.length,
              itemBuilder: (_, i) {
                final e = q[i];
                return ListTile(
                  leading: Text('#${i + 1}'),
                  title: Text(e.meta.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${e.meta.artist} · ${e.by?.name ?? ""}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(e.status == 'preparing' ? '准备中' : ''),
                );
              },
            );
          }),
        ]),
      ),
    ]);
  }
}
