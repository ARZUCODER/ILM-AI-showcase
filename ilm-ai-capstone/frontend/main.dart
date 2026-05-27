import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Firebase kutubxonalari
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // flutterfire yaratib bergan fayl

import 'core/routing/router.dart';
import 'core/theme/liq_colors.dart';

void main() async {
  // Flutter dvigateli ishga tushishiga ishonch hosil qilish
  WidgetsFlutterBinding.ensureInitialized();

  // .env faylni o'qish
  await dotenv.load(fileName: ".env");

  // Yordamchi: Firebase'ni inicializatsiya qilish
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // UI dizayn sozlamalari
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: LiqColors.bgDeep,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: IlmAiApp()));
}

class IlmAiApp extends ConsumerWidget {
  const IlmAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LiqColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: LiqColors.accent,
        secondary: LiqColors.accentSoft,
        surface: LiqColors.surface,
        onPrimary: Colors.white,
      ),
      useMaterial3: true,
    );

    return MaterialApp.router(
      title: 'ILM AI',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
          bodyColor: LiqColors.textPrimary,
          displayColor: LiqColors.textPrimary,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}