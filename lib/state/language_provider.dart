import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  Locale _locale = const Locale('de');

  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  bool get isGerman => _locale.languageCode == 'de';

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    final savedLanguage = prefs.getString(_languageKey);

    if (savedLanguage != null) {
      _locale = Locale(savedLanguage);
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (languageCode != 'ar' && languageCode != 'de') {
      return;
    }

    _locale = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    if (isArabic) {
      await changeLanguage('de');
    } else {
      await changeLanguage('ar');
    }
  }
}