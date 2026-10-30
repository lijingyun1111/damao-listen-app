/// AListen WS 连接管理：单读者 + per-id future + 自动重连 + 指数退避
/// 翻译自官方 connection.ts 语义；Dart 天然单事件循环，无并发 recv 问题
library;

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../protocol/types.dart';

const protocolVersion = '09dbf7ea495db969';

/// 与官方一致的"停止重连"关闭码
const stopCodes = {4401, 4404, 4426}; // unauthorized / notFound / clientOutdated

enum ConnStatus { connecting, connected, reconnecting, halted }

class RoomConnection {
  WebSocketChannel? _socket;
  final Map<String, Completer<dynamic>> _pending = {};
  final _roomEvents = StreamController<Map<String, dynamic>>.broadcast();
  final _status = StreamController<ConnStatus>.broadcast();
  Timer? _pingTimer;
  Timer? _retryTimer;
  int _attempt = 0;
  int _seq = 0;
  bool _ready = false;
  bool _halted = false;
  String _roomId;
  String _ticket;

  RoomConnection({required String roomId, required String ticket})
      : _roomId = roomId,
        _ticket = ticket;

  Stream<ConnStatus> get statusStream => _status.stream;
  Stream<Map<String, dynamic>> get roomEventStream => _roomEvents.stream;
  bool get isConnected => _ready;

  void updateTicket(String ticket) => _ticket = ticket;

  Future<void> connect() async {
    _halted = false;
    _setStatus(ConnStatus.connecting);
    final uri = Uri.parse('wss://livehouse.dihe.moe/ws');
    _socket = WebSocketChannel.connect(uri);
    await _socket!.ready;
    // 握手必须是第一帧
    final hello = await request('hello', {
      'roomId': _roomId,
      'ticket': _ticket,
      'protocolVersion': protocolVersion,
    });
    _ready = true;
    _attempt = 0;
    _setStatus(ConnStatus.connected);
    // ping 心跳：官方前端 30s 一跳
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        await request('ping', {});
      } catch (_) {}
    });
    // 丢弃 hello 快照细节（replica 从 room.sync 重建），启动监听
    _listen();
  }

  void _listen() {
    _socket!.stream.listen((raw) {
      dynamic msg;
      try {
        msg = jsonDecode(raw as String);
      } catch (_) {
        return;
      }
      if (msg is! Map<String, dynamic>) return;
      final kind = msg['kind'];
      if (kind == 'response') {
        final id = msg['id'] as String?;
        final c = _pending.remove(id);
        if (c != null && !c.isCompleted) {
          if (msg['error'] != null) {
            c.completeError(
                RequestError(msg['error']['message'] ?? '请求失败', msg['error']['code']));
          } else {
            c.complete(msg['data']);
          }
        }
      } else if (kind == 'event') {
        if (msg['type'] == 'error') {
          // 会话级错误：忽略或上报日志
        } else if (_ready) {
          _roomEvents.add(msg);
        }
      }
    }, onError: (_) => _lost(null), onDone: () => _lost(null));
  }

  void _lost(int? code) {
    _ready = false;
    _pingTimer?.cancel();
    _socket = null;
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(RequestError('与房间的连接断开了'));
    }
    _pending.clear();
    if (_halted) return;
    if (code != null && stopCodes.contains(code)) {
      _halted = true;
      _setStatus(ConnStatus.halted);
      return;
    }
    _attempt += 1;
    _setStatus(ConnStatus.reconnecting);
    final delay = Duration(seconds: _attempt > 5 ? 30 : 2 * _attempt);
    _retryTimer = Timer(delay, () => connect().catchError((_) {}));
  }

  Future<dynamic> request(String type, Map<String, dynamic> data,
      {Duration timeout = const Duration(seconds: 25)}) async {
    final id = 'r${++_seq}';
    final c = Completer<dynamic>();
    _pending[id] = c;
    _socket?.sink.add(jsonEncode(
        {'kind': 'request', 'type': type, 'id': id, 'data': data}));
    try {
      return await c.future.timeout(timeout);
    } on TimeoutException {
      _pending.remove(id);
      throw RequestError('请求超时');
    }
  }

  // ---------- 高层 API ----------
  Future<RoomSnapshot> roomSync() async {
    final r = await request('room.sync', {});
    return RoomSnapshot.fromJson(r);
  }

  Future<Entry> queueAddTrack(Track track) async {
    final r = await request('queue.add', {'track': track.toJson()});
    return Entry.fromJson(r['entry']);
  }

  Future<Entry> queueAddKeyword(Source source, String keyword) async {
    final r = await request(
        'queue.add', {'source': source.name, 'keyword': keyword});
    return Entry.fromJson(r['entry']);
  }

  Future<void> queueRemove(String entryId) async =>
      await request('queue.remove', {'entryId': entryId});

  Future<int> queueLike(String entryId) async {
    final r = await request('queue.like', {'entryId': entryId});
    return r['likes'] ?? 0;
  }

  Future<void> chatSend(String content) async =>
      await request('chat.send', {'content': content});

  Future<List<SearchTrackItem>> searchTracks(String keyword,
      {Source source = Source.netease, int page = 1, int pageSize = 8}) async {
    final r = await request('search.tracks', {
      'keyword': keyword,
      'page': page,
      'pageSize': pageSize,
      'source': source.name,
    });
    return (r['items'] as List? ?? [])
        .map((e) => SearchTrackItem.fromJson(e))
        .toList();
  }

  Future<void> voteSkip() async => await request('playback.voteSkip', {});

  void close() {
    _halted = true;
    _pingTimer?.cancel();
    _retryTimer?.cancel();
    _socket?.sink.close();
    _status.close();
    _roomEvents.close();
  }

  void _setStatus(ConnStatus s) => _status.add(s);
}
