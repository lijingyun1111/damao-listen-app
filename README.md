# 大猫听歌房 App

> ⚠️ **本项目由 AI（Hermes Agent + DeepSeek/GLM 大模型）全程编写，人类只负责提需求、测试和验收。**

[AListen](https://github.com/DiheMoe/alisten) 的 Flutter 原生客户端（Android）。解决"手机浏览器后台被杀、听歌断线"的问题。

## 功能

- **原生 WS 长连接**：前台服务保活（通知栏常驻），app 退到后台/锁屏不掉线
- 进房：昵称自定义、房间密码支持，member token 本地持久化（重开不用重新进）
- 点歌：关键词搜索（网易云/QQ 音乐），一键排队
- 队列实时同步：正在播放/待播列表/在线人数
- 聊天室：收发消息
- 投票切歌

## 安装

1. 下载 APK（Releases）
2. 允许"安装未知来源应用"
3. 输入房间密码 → 进房
4. **保持通知栏常驻**（保活的关键，别划掉）

## 架构

```
lib/
├── core/
│   ├── protocol/types.dart      # 协议类型（翻译自官方 idl.json / protocol.gen.ts）
│   ├── realtime/connection.dart # WS 连接：单读者 + per-id future + 指数退避重连
│   ├── api/auth_api.dart        # HTTP：/api/members、/api/me、/api/rooms/{id}/tickets
│   └── storage/local_store.dart # 本地持久化
└── features/
    ├── onboarding/enter_page.dart  # 进房页
    ├── room/room_page.dart         # 房间主页（状态编排）
    ├── room/search_sheet.dart      # 点歌搜索
    ├── player/now_playing_bar.dart # 正在播放条
    └── chat/chat_panel.dart        # 聊天 + 队列
```

## 开发

```bash
flutter pub get
flutter run
flutter build apk --release
```

## 许可

GPL-3.0（跟随上游 DiheMoe/alisten）。服务端请使用 DiheMoe/alisten 自行部署或访问官方实例。
