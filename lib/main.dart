/// 大猫听歌房 —— AListen 原生客户端（Flutter）
/// 本项目由 AI（Hermes Agent）编写，人类负责提需求与验收。GPL-3.
library;

import 'package:flutter/material.dart';
import 'features/onboarding/enter_page.dart';
import 'core/storage/local_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.init();
  runApp(const DamaoApp());
}

class DamaoApp extends StatelessWidget {
  const DamaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '大猫听歌房',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A6CF7), brightness: Brightness.dark),
      ),
      home: const EnterPage(),
    );
  }
}
