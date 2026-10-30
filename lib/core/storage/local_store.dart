/// 本地持久化：member token / 房间 / 昵称（shared_preferences）
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static late SharedPreferences _p;

  static Future<void> init() async => _p = await SharedPreferences.getInstance();

  static String? get memberToken => _p.getString('memberToken');
  static set memberToken(String? v) =>
      v == null ? _p.remove('memberToken') : _p.setString('memberToken', v);

  static String? get displayName => _p.getString('displayName');
  static set displayName(String? v) =>
      v == null ? _p.remove('displayName') : _p.setString('displayName', v);

  static String get roomId =>
      _p.getString('roomId') ?? '01a188f7-f268-7796-8e83-de9f700d0f50';
  static set roomId(String? v) =>
      v == null ? _p.remove('roomId') : _p.setString('roomId', v);

  /// 记住的房间密码（本机存储，可选）
  static String? get roomPassword => _p.getString('roomPassword');
  static set roomPassword(String? v) =>
      v == null ? _p.remove('roomPassword') : _p.setString('roomPassword', v);

  /// 最近点歌历史（JSON list）
  static List<Map<String, dynamic>> get history {
    final s = _p.getString('history');
    if (s == null) return [];
    return (jsonDecode(s) as List).cast<Map<String, dynamic>>();
  }

  static void addHistory(String title, String artist) {
    final h = history;
    h.insert(0, {'title': title, 'artist': artist, 'ts': DateTime.now().millisecondsSinceEpoch});
    if (h.length > 50) h.removeRange(50, h.length);
    _p.setString('history', jsonEncode(h));
  }
}
