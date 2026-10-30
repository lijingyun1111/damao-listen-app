/// 点歌搜索弹层：关键词 → 音源选择 → 结果列表 → 点击即排队
library;

import 'package:flutter/material.dart';
import '../../core/protocol/types.dart';
import '../../core/realtime/connection.dart';

class SearchSheet extends StatefulWidget {
  final RoomConnection conn;
  const SearchSheet({super.key, required this.conn});
  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  final _kw = TextEditingController();
  Source _source = Source.netease;
  List<SearchTrackItem>? _results;
  bool _busy = false;
  String? _error;

  Future<void> _search() async {
    final k = _kw.text.trim();
    if (k.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final items = await widget.conn.searchTracks(k, source: _source, pageSize: 20);
      setState(() {
        _results = items;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '搜索失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _kw,
                  autofocus: true,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                      hintText: '搜歌名 / 歌手',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<Source>(
                segments: const [
                  ButtonSegment(value: Source.netease, label: Text('网易')),
                  ButtonSegment(value: Source.qq, label: Text('Q Q')),
                ],
                selected: {_source},
                onSelectionChanged: (s) => setState(() => _source = s.first),
              ),
            ]),
          ),
          Expanded(
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : (_results == null || _results!.isEmpty)
                        ? const Center(child: Text('输入关键词搜歌'))
                        : ListView.builder(
                            itemCount: _results!.length,
                            itemBuilder: (_, i) {
                              final it = _results![i];
                              return ListTile(
                                leading: Text('${i + 1}'),
                                title: Text(it.meta.title,
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(it.meta.artist,
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: Text(_fmt(it.meta.durationMs)),
                                onTap: () => Navigator.pop(context, it),
                              );
                            },
                          ),
          ),
        ]),
      ),
    );
  }

  String _fmt(int ms) {
    if (ms <= 0) return '';
    final m = ms ~/ 60000, s = (ms % 60000) ~/ 1000;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
