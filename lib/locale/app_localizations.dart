import 'package:booking_system_flutter/locale/language_ar.dart';
import 'package:booking_system_flutter/locale/language_en.dart';
import 'package:booking_system_flutter/locale/languages.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class AppLocalizations extends LocalizationsDelegate<BaseLanguage> {
  const AppLocalizations();

  @override
  Future<BaseLanguage> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'en':
        return LanguageEn();
      case 'ar':
        return LanguageAr();
      default:
        return LanguageEn();
    }
  }

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode); // بس عربي وإنجليزي

  @override
  bool shouldReload(LocalizationsDelegate<BaseLanguage> old) => false;
}
