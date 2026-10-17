import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'translations_fr.dart';
import 'translations_ar.dart';
import 'translations_en.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    try {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      return AppLocalizations(langProvider.currentLocale);
    } catch (_) {
      return AppLocalizations(const Locale('fr'));
    }
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'fr': translationsFr,
    'ar': translationsAr,
    'en': translationsEn,
  };

  String tr(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ??
        _localizedValues['fr']?[key] ??
        key;
  }
}

extension LocalizationExtension on BuildContext {
  String tr(String key) => AppLocalizations.of(this).tr(key);
}
