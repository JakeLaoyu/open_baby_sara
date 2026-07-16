import 'package:flutter/painting.dart';
import 'package:open_baby_sara/data/models/locale_model.dart';

const supportedLocales = [
  LocaleModel(name: 'English', flag: '🇺🇸', locale: Locale('en', 'US')),
  LocaleModel(name: 'Türkçe', flag: '🇹🇷', locale: Locale('tr', 'TR')),
  LocaleModel(name: 'Deutsch', flag: '🇩🇪', locale: Locale('de', 'DE')),
  LocaleModel(name: 'Español', flag: '🇪🇸', locale: Locale('es', 'ES')),
  LocaleModel(name: 'Français', flag: '🇫🇷', locale: Locale('fr', 'FR')),
  LocaleModel(name: 'العربية', flag: '🇸🇦', locale: Locale('ar', 'SA')),
  LocaleModel(name: '简体中文', flag: '🇨🇳', locale: Locale('zh', 'CN')),
  LocaleModel(name: '繁體中文', flag: '🇹🇼', locale: Locale('zh', 'TW')),
  LocaleModel(name: 'Nederlands', flag: '🇳🇱', locale: Locale('nl', 'NL')),
  LocaleModel(name: 'Русский', flag: '🇷🇺', locale: Locale('ru', 'RU')),
  LocaleModel(name: '한국어', flag: '🇰🇷', locale: Locale('ko', 'KR')),
  LocaleModel(
    name: 'Bahasa Indonesia',
    flag: '🇮🇩',
    locale: Locale('id', 'ID'),
  ),
];
