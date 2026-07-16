import 'package:flutter/painting.dart';
import 'package:open_baby_sara/data/models/locale_model.dart';

const supportedLocales = [
  LocaleModel(name: 'English', flag: '🇺🇸', locale: Locale('en', 'US')),
  LocaleModel(name: 'Türkçe', flag: '🇹🇷', locale: Locale('tr', 'TR')),
  LocaleModel(name: 'Deutsch', flag: '🇩🇪', locale: Locale('de', 'DE')),
  LocaleModel(name: 'Español', flag: '🇪🇸', locale: Locale('es', 'ES')),
  LocaleModel(name: 'Français', flag: '🇫🇷', locale: Locale('fr', 'FR')),
  LocaleModel(name: 'العربية', flag: '🇸🇦', locale: Locale('ar', 'SA')),
  // zh-TW must precede zh-CN: easy_localization falls back to the first
  // locale with a matching languageCode, and zh devices without an exact
  // match (zh-Hant, zh_HK, zh_MO, plain zh) resolved to zh-TW before
  // zh-CN existed. Devices reporting zh_CN / zh-Hans-CN match exactly,
  // so this order does not affect them.
  LocaleModel(name: '繁體中文', flag: '🇹🇼', locale: Locale('zh', 'TW')),
  LocaleModel(name: '简体中文', flag: '🇨🇳', locale: Locale('zh', 'CN')),
  LocaleModel(name: 'Nederlands', flag: '🇳🇱', locale: Locale('nl', 'NL')),
  LocaleModel(name: 'Русский', flag: '🇷🇺', locale: Locale('ru', 'RU')),
  LocaleModel(name: '한국어', flag: '🇰🇷', locale: Locale('ko', 'KR')),
  LocaleModel(
    name: 'Bahasa Indonesia',
    flag: '🇮🇩',
    locale: Locale('id', 'ID'),
  ),
];

/// Script-only Chinese locales used for device-locale matching. They are not
/// shown in the language picker; ScriptAwareAssetLoader maps them onto the
/// zh-CN / zh-TW translation files. Keep them AFTER the picker locales so
/// exact country matches (zh_CN, zh_TW) win first.
const scriptMatchingLocales = [
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
];
