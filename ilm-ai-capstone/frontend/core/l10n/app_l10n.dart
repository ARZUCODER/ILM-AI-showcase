import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _supported = ['uz', 'ru', 'en'];

String _deviceLocale() {
  final tag = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
  if (_supported.contains(tag)) return tag;
  // Rus tilida so'zlashuvchi davlatlar uchun
  final country = PlatformDispatcher.instance.locale.countryCode?.toUpperCase() ?? '';
  if (['RU', 'KZ', 'KG', 'TJ', 'BY', 'MD', 'AZ', 'AM', 'GE'].contains(country)) return 'ru';
  return 'en';
}

class AppL10n {
  final Map<String, String> _map;
  AppL10n(this._map);

  String t(String key) => _map[key] ?? key;

  String tr(String key, Map<String, String> args) {
    String value = _map[key] ?? key;
    for (final entry in args.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  static Future<AppL10n> load(String code) async {
    try {
      final json = await rootBundle.loadString('assets/translations/$code.json');
      final map = Map<String, dynamic>.from(jsonDecode(json));
      return AppL10n(map.cast<String, String>());
    } catch (_) {
      return AppL10n({});
    }
  }
}

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super(_deviceLocale()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    // Foydalanuvchi avval til tanlagan bo'lsa, shuni ishlatamiz
    // Aks holda qurilma tili saqlanmagan — state allaqachon _deviceLocale() bilan o'rnatilgan
    final saved = prefs.getString('locale');
    if (saved != null && _supported.contains(saved)) {
      state = saved;
    }
  }

  Future<void> setLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
    state = code;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, String>(
  (ref) => LocaleNotifier(),
);

final l10nProvider = FutureProvider<AppL10n>((ref) {
  final code = ref.watch(localeProvider);
  return AppL10n.load(code);
});
