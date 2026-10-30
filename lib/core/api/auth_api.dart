/// AListen HTTP API：建身份 / 改名 / 换房票
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'https://livehouse.dihe.moe';

class AuthApi {
  String? memberToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Origin': baseUrl,
        if (memberToken != null) 'Authorization': 'Bearer $memberToken',
      };

  /// 建新身份（浏览器无痕打开站点等效）
  Future<String> createMember() async {
    final r = await http.post(Uri.parse('$baseUrl/api/members'),
        headers: _headers, body: '{}');
    if (r.statusCode >= 400) throw Exception('创建身份失败 ${r.statusCode}');
    final d = jsonDecode(r.body);
    memberToken = d['memberToken'];
    return memberToken!;
  }

  Future<void> rename(String name) async {
    final r = await http.patch(Uri.parse('$baseUrl/api/me'),
        headers: _headers, body: jsonEncode({'name': name}));
    if (r.statusCode >= 400) throw Exception('改名失败 ${r.statusCode}');
  }

  Future<void> setEmail(String email) async {
    final r = await http.patch(Uri.parse('$baseUrl/api/me'),
        headers: _headers, body: jsonEncode({'email': email}));
    if (r.statusCode >= 400) throw Exception('设置邮箱失败 ${r.statusCode}');
  }

  /// 换房票（有密码的房间）
  Future<String> getTicket(String roomId, {String? password}) async {
    final r = await http.post(Uri.parse('$baseUrl/api/rooms/$roomId/tickets'),
        headers: _headers,
        body: jsonEncode(password == null ? {} : {'password': password}));
    if (r.statusCode >= 400) {
      if (r.statusCode == 403 || r.statusCode == 401) {
        throw Exception('房间密码不对喵');
      }
      throw Exception('进房失败 ${r.statusCode}');
    }
    return jsonDecode(r.body)['ticket'];
  }

  /// 恢复上次登录（token 持久化在本地）
  Future<bool> resume(String savedToken) async {
    memberToken = savedToken;
    try {
      final r = await http.get(Uri.parse('$baseUrl/api/me'), headers: _headers);
      return r.statusCode < 400;
    } catch (_) {
      return false;
    }
  }
}
