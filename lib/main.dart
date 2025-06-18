import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/colors.dart';
import 'package:flutter/services.dart';

import 'views/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock device orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    ProviderScope(
      // 🌱 Riverpod root
      child: NaniTVApp(),
    ),
  );
}

class NaniTVApp extends StatelessWidget {
  const NaniTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // 🔁 GetX-powered navigation
      debugShowCheckedModeBanner: false,
      title: 'NaniTV',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: SplashScreen(),
    );
  }
}
