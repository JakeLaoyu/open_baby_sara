import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';

/// Routes script-only Chinese locales to the existing translation files so
/// devices reporting zh-Hans-* / zh-Hant-* with a region other than CN / TW
/// (e.g. zh-Hans-SG, zh-Hant-HK) still load the matching script instead of
/// falling back to the first zh locale.
class ScriptAwareAssetLoader extends RootBundleAssetLoader {
  const ScriptAwareAssetLoader();

  @override
  String getLocalePath(String basePath, Locale locale) {
    if (locale.languageCode == 'zh' && locale.scriptCode == 'Hans') {
      return '$basePath/zh-CN.json';
    }
    if (locale.languageCode == 'zh' && locale.scriptCode == 'Hant') {
      return '$basePath/zh-TW.json';
    }
    return super.getLocalePath(basePath, locale);
  }
}
