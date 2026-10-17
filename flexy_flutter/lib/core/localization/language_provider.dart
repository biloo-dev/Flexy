import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'fr'; // Default French

  String get currentLanguage => _currentLanguage;
  Locale get currentLocale => Locale(_currentLanguage);
  TextDirection get textDirection =>
      _currentLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  bool get isRtl => _currentLanguage == 'ar';

  void setLanguage(String langCode) {
    if (_currentLanguage != langCode) {
      _currentLanguage = langCode;
      notifyListeners();
    }
  }
}
