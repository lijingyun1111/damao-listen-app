/// 进房页：昵称（可选改）+ 房间密码（若需要）→ 连接 → 进房间主页
library;

import 'package:flutter/material.dart';
import '../../core/api/auth_api.dart';
import '../../core/realtime/connection.dart';
import '../../core/storage/local_store.dart';
import '../room/room_page.dart';

class EnterPage extends StatefulWidget {
  const EnterPage({super.key});
  @override
  State<EnterPage> createState() => _EnterPageState();
}

class _EnterPageState extends State<EnterPage> {
  final _nameCtrl = TextEditingController(text: LocalStore.displayName ?? '');
  final _pwdCtrl = TextEditingController(text: LocalStore.roomPassword ?? '');
  bool _busy = false;
  String? _error;

  Future<void> _enter() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = AuthApi();
      // 复用 token，失败则新建身份
      final saved = LocalStore.memberToken;
      var ok = saved != null && await api.resume(saved);
      if (!ok) await api.createMember();
      final name = _nameCtrl.text.trim();
      if (name.isNotEmpty && name != LocalStore.displayName) {
        await api.rename(name);
        LocalStore.displayName = name;
      }
      if (_pwdCtrl.text.isNotEmpty) LocalStore.roomPassword = _pwdCtrl.text;

      final ticket = await api.getTicket(LocalStore.roomId,
          password: LocalStore.roomPassword);
      LocalStore.memberToken = api.memberToken;

      final conn = RoomConnection(roomId: LocalStore.roomId, ticket: ticket);
      await conn.connect();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => RoomPage(conn: conn, me: name.isNotEmpty ? name : '听友')));
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Icon(Icons.music_note, size: 64, color: Color(0xFF7C9BFF)),
              const SizedBox(height: 12),
              const Text('大猫听歌房',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const Text('一起听歌吧', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54)),
              const Spacer(flex: 2),
              TextField(
                controller: _nameCtrl,
                maxLength: 16,
                decoration: const InputDecoration(
                    labelText: '昵称（留空随机）', prefixIcon: Icon(Icons.person)),
              ),
              TextField(
                controller: _pwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: '房间密码', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _enter,
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _busy
                    ? const SizedBox(height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('进 房', style: TextStyle(fontSize: 17)),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
