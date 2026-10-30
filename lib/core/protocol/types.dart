/// AListen 协议类型（手工翻译自官方 protocol.gen.ts / idl.json）
/// 与 DiheMoe/alisten 服务端协议一致，GPL-3，项目由 AI 编写
library;

class Member {
  final String id;
  final String name;
  final String? avatarHash;
  Member({required this.id, required this.name, this.avatarHash});
  factory Member.fromJson(Map<String, dynamic> j) => Member(
      id: j['id'], name: j['name'], avatarHash: j['avatarHash']);
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, if (avatarHash != null) 'avatarHash': avatarHash};
}

enum Source { netease, qq, bilibili, link }

Source sourceFromString(String s) => Source.values.firstWhere(
    (e) => e.name == s,
    orElse: () => Source.netease);

class Track {
  final Source source;
  final String id;
  Track({required this.source, required this.id});
  factory Track.fromJson(Map<String, dynamic> j) =>
      Track(source: sourceFromString(j['source']), id: j['id']);
  Map<String, dynamic> toJson() => {'source': source.name, 'id': id};
}

class TrackMeta {
  final String title;
  final String artist;
  final String album;
  final String? coverUrl;
  final String pageUrl;
  final int durationMs;
  TrackMeta(
      {required this.title,
      required this.artist,
      required this.album,
      this.coverUrl,
      required this.pageUrl,
      required this.durationMs});
  factory TrackMeta.fromJson(Map<String, dynamic> j) => TrackMeta(
      title: j['title'] ?? '',
      artist: j['artist'] ?? '',
      album: j['album'] ?? '',
      coverUrl: j['coverUrl'],
      pageUrl: j['pageUrl'] ?? '',
      durationMs: j['durationMs'] ?? 0);
}

class Entry {
  final String id;
  final Track track;
  final TrackMeta meta;
  final Member? by;
  final bool auto;
  final int likes;
  final String status; // preparing | ready | played
  Entry(
      {required this.id,
      required this.track,
      required this.meta,
      this.by,
      required this.auto,
      required this.likes,
      required this.status});
  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
      id: j['id'],
      track: Track.fromJson(j['track']),
      meta: TrackMeta.fromJson(j['meta']),
      by: j['by'] == null ? null : Member.fromJson(j['by']),
      auto: j['auto'] ?? false,
      likes: j['likes'] ?? 0,
      status: j['status'] ?? 'ready');
}

class LyricLine {
  final int timeMs;
  final String content;
  LyricLine({required this.timeMs, required this.content});
  factory LyricLine.fromJson(Map<String, dynamic> j) =>
      LyricLine(timeMs: j['timeMs'] ?? 0, content: j['content'] ?? '');
}

class NowPlaying {
  final Entry? entry;
  final String mediaUrl;
  final int startedAtMs;
  final int durationMs;
  final double gain;
  final List<LyricLine>? lyric;
  NowPlaying(
      {this.entry,
      required this.mediaUrl,
      required this.startedAtMs,
      required this.durationMs,
      required this.gain,
      this.lyric});
  factory NowPlaying.fromJson(Map<String, dynamic> j) => NowPlaying(
      entry: j['entry'] == null ? null : Entry.fromJson(j['entry']),
      mediaUrl: j['mediaUrl'] ?? '',
      startedAtMs: j['startedAtMs'] ?? 0,
      durationMs: j['durationMs'] ?? 0,
      gain: (j['gain'] as num?)?.toDouble() ?? 1.0,
      lyric: (j['lyric'] as List?)
          ?.map((e) => LyricLine.fromJson(e))
          .toList());
}

enum PlayMode { sequential, repeatAll, random }

class RoomInfo {
  final String id;
  final String name;
  final String? description;
  final String kind;
  RoomInfo(
      {required this.id, required this.name, this.description, required this.kind});
  factory RoomInfo.fromJson(Map<String, dynamic> j) => RoomInfo(
      id: j['id'],
      name: j['name'],
      description: j['description'],
      kind: j['kind'] ?? 'room');
}

class RoomSnapshot {
  final int term;
  final int seq;
  final RoomInfo room;
  final NowPlaying? nowPlaying;
  final Entry? pending;
  final List<Entry> items;
  final List<Member> members;
  RoomSnapshot(
      {required this.term,
      required this.seq,
      required this.room,
      this.nowPlaying,
      this.pending,
      required this.items,
      required this.members});
  factory RoomSnapshot.fromJson(Map<String, dynamic> j) => RoomSnapshot(
      term: j['term'] ?? 0,
      seq: j['seq'] ?? 0,
      room: RoomInfo.fromJson(j['room']),
      nowPlaying: j['nowPlaying'] == null
          ? null
          : NowPlaying.fromJson(j['nowPlaying']),
      pending: j['pending'] == null ? null : Entry.fromJson(j['pending']),
      items: (j['items'] as List? ?? []).map((e) => Entry.fromJson(e)).toList(),
      members: (j['members'] as List? ?? [])
          .map((e) => Member.fromJson(e))
          .toList());
}

// ---------- 事件 ----------

class ChatMessageEvent {
  final String content;
  final Member member;
  final int sentAtMs;
  ChatMessageEvent(
      {required this.content, required this.member, required this.sentAtMs});
  factory ChatMessageEvent.fromJson(Map<String, dynamic> j) =>
      ChatMessageEvent(
          content: j['content'] ?? '',
          member: Member.fromJson(j['member']),
          sentAtMs: j['sentAtMs'] ?? 0);
}

class QueueUpdatedEvent {
  final List<Entry> items;
  final Entry? pending;
  QueueUpdatedEvent({required this.items, this.pending});
  factory QueueUpdatedEvent.fromJson(Map<String, dynamic> j) =>
      QueueUpdatedEvent(
          items: (j['items'] as List? ?? []).map((e) => Entry.fromJson(e)).toList(),
          pending: j['pending'] == null ? null : Entry.fromJson(j['pending']));
}

class RoomUpdatedEvent {
  final RoomInfo room;
  RoomUpdatedEvent({required this.room});
  factory RoomUpdatedEvent.fromJson(Map<String, dynamic> j) =>
      RoomUpdatedEvent(room: RoomInfo.fromJson(j['room']));
}

// ---------- 请求/响应包装 ----------

class SearchTrackItem {
  final Track track;
  final TrackMeta meta;
  SearchTrackItem({required this.track, required this.meta});
  factory SearchTrackItem.fromJson(Map<String, dynamic> j) =>
      SearchTrackItem(track: Track.fromJson(j['track']), meta: TrackMeta.fromJson(j['meta']));
}

class RequestError implements Exception {
  final String message;
  final String? code;
  RequestError(this.message, [this.code]);
  @override
  String toString() => message;
}
