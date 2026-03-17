import 'dart:ui';

class AppLocaleOption {
  const AppLocaleOption({required this.code, required this.locale});

  final String code;
  final Locale locale;
}

const appLocaleEnUs = AppLocaleOption(code: 'en', locale: Locale('en'));

const appLocaleZhHansCn = AppLocaleOption(
  code: 'zh_Hans',
  locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
);

const appLocaleZhHantTw = AppLocaleOption(
  code: 'zh_Hant',
  locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
);

const appLocaleJaJp = AppLocaleOption(code: 'ja', locale: Locale('ja'));

const appLocaleKoKr = AppLocaleOption(code: 'ko', locale: Locale('ko'));

const supportedAppLocaleOptions = <AppLocaleOption>[
  appLocaleEnUs,
  appLocaleZhHansCn,
  appLocaleZhHantTw,
  appLocaleJaJp,
  appLocaleKoKr,
];

AppLocaleOption? appLocaleOptionFromCode(String? code) {
  if (code == null || code.isEmpty) {
    return null;
  }
  switch (code) {
    case 'en_US':
      code = 'en';
      break;
    case 'zh_Hans_CN':
      code = 'zh_Hans';
      break;
    case 'zh_Hant_TW':
      code = 'zh_Hant';
      break;
    case 'ja_JP':
      code = 'ja';
      break;
    case 'ko_KR':
      code = 'ko';
      break;
  }
  for (final option in supportedAppLocaleOptions) {
    if (option.code == code) {
      return option;
    }
  }
  return null;
}

Locale resolveSupportedAppLocale([Iterable<Locale>? preferredLocales]) {
  final locales = preferredLocales == null || preferredLocales.isEmpty
      ? const <Locale>[Locale('en')]
      : preferredLocales;
  for (final locale in locales) {
    final language = locale.languageCode.toLowerCase();
    final country = (locale.countryCode ?? '').toUpperCase();
    final script = (locale.scriptCode ?? '').toLowerCase();
    if (language == 'zh') {
      if (script == 'hant' ||
          country == 'TW' ||
          country == 'HK' ||
          country == 'MO') {
        return appLocaleZhHantTw.locale;
      }
      return appLocaleZhHansCn.locale;
    }
    if (language == 'ja') {
      return appLocaleJaJp.locale;
    }
    if (language == 'ko') {
      return appLocaleKoKr.locale;
    }
    if (language == 'en') {
      return appLocaleEnUs.locale;
    }
  }
  return appLocaleEnUs.locale;
}
