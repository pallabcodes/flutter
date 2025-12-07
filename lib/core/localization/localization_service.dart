import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide TextDirection;
import 'package:flutter/services.dart';
import 'package:finwise/core/security/secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Enterprise internationalization service
/// Supports 20+ languages with dynamic locale switching and cultural adaptation
class LocalizationService {
  static const String _localeKey = 'user_locale';
  static const String _fallbackLocale = 'en';

  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  final Map<String, Map<String, String>> _localizedStrings = {};
  final Map<String, Locale> _supportedLocales = {};

  Locale _currentLocale = const Locale(_fallbackLocale);
  bool _isInitialized = false;

  // Supported locales with native names
  static const Map<String, Map<String, String>> _localeDefinitions = {
    'en': {'name': 'English', 'nativeName': 'English', 'flag': '🇺🇸'},
    'es': {'name': 'Spanish', 'nativeName': 'Español', 'flag': '🇪🇸'},
    'fr': {'name': 'French', 'nativeName': 'Français', 'flag': '🇫🇷'},
    'de': {'name': 'German', 'nativeName': 'Deutsch', 'flag': '🇩🇪'},
    'it': {'name': 'Italian', 'nativeName': 'Italiano', 'flag': '🇮🇹'},
    'pt': {'name': 'Portuguese', 'nativeName': 'Português', 'flag': '🇵🇹'},
    'ru': {'name': 'Russian', 'nativeName': 'Русский', 'flag': '🇷🇺'},
    'ja': {'name': 'Japanese', 'nativeName': '日本語', 'flag': '🇯🇵'},
    'ko': {'name': 'Korean', 'nativeName': '한국어', 'flag': '🇰🇷'},
    'zh': {'name': 'Chinese', 'nativeName': '中文', 'flag': '🇨🇳'},
    'ar': {'name': 'Arabic', 'nativeName': 'العربية', 'flag': '🇸🇦'},
    'hi': {'name': 'Hindi', 'nativeName': 'हिन्दी', 'flag': '🇮🇳'},
    'bn': {'name': 'Bengali', 'nativeName': 'বাংলা', 'flag': '🇧🇩'},
    'pa': {'name': 'Punjabi', 'nativeName': 'ਪੰਜਾਬੀ', 'flag': '🇮🇳'},
    'te': {'name': 'Telugu', 'nativeName': 'తెలుగు', 'flag': '🇮🇳'},
    'mr': {'name': 'Marathi', 'nativeName': 'मराठी', 'flag': '🇮🇳'},
    'ta': {'name': 'Tamil', 'nativeName': 'தமிழ்', 'flag': '🇮🇳'},
    'ur': {'name': 'Urdu', 'nativeName': 'اردو', 'flag': '🇵🇰'},
    'gu': {'name': 'Gujarati', 'nativeName': 'ગુજરાતી', 'flag': '🇮🇳'},
    'kn': {'name': 'Kannada', 'nativeName': 'ಕನ್ನಡ', 'flag': '🇮🇳'},
  };

  /// Initialize localization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load device locale or saved preference
    await _loadSavedLocale();

    // Load supported locales
    _loadSupportedLocales();

    // Load localization files
    await _loadLocalizationFiles();

    // Configure date formatting
    await _configureDateFormatting();

    _isInitialized = true;
  }

  /// Get current locale
  Locale get currentLocale => _currentLocale;

  /// Get current language code
  String get currentLanguageCode => _currentLocale.languageCode;

  /// Get list of supported locales
  List<Locale> get supportedLocales => _supportedLocales.values.toList();

  /// Get locale display information
  List<Map<String, String>> get supportedLocaleInfo {
    return _localeDefinitions.entries.map((entry) {
      final code = entry.key;
      final info = entry.value;
      return <String, String>{
        'code': code,
        'name': info['name']!.toString(),
        'nativeName': info['nativeName']!.toString(),
        'flag': info['flag']!.toString(),
        'isCurrent': (code == currentLanguageCode).toString(),
      };
    }).toList();
  }

  /// Change locale
  Future<void> changeLocale(String languageCode) async {
    if (!_localeDefinitions.containsKey(languageCode)) {
      throw Exception('Unsupported locale: $languageCode');
    }

    final newLocale = Locale(languageCode);
    _currentLocale = newLocale;

    // Save preference
    await SecureStorage.storeEncryptedData(_localeKey, languageCode);

    // Reload date formatting for new locale
    await _configureDateFormatting();

    // Notify listeners (would be implemented with provider/riverpod)
    _notifyLocaleChange(newLocale);
  }

  /// Get localized string
  String translate(String key, {Map<String, String>? args}) {
    final languageCode = _currentLocale.languageCode;

    // Try current locale first
    var translation = _localizedStrings[languageCode]?[key];

    // Fallback to base language (e.g., 'zh' for 'zh-CN')
    if (translation == null && languageCode.contains('-')) {
      final baseLanguage = languageCode.split('-')[0];
      translation = _localizedStrings[baseLanguage]?[key];
    }

    // Final fallback to English
    if (translation == null) {
      translation = _localizedStrings[_fallbackLocale]?[key];
    }

    // Final fallback to key itself
    translation ??= key;

    // Apply arguments if provided
    if (args != null) {
      args.forEach((placeholder, value) {
        translation = translation!.replaceAll('{{$placeholder}}', value);
      });
    }

    return translation ?? key;
  }

  /// Get pluralized string
  String translatePlural(String key, int count, {Map<String, String>? args}) {
    final pluralKey = count == 1 ? '${key}_one' : '${key}_other';
    final translation = translate(pluralKey, args: args);

    // If no plural form exists, use singular with count
    if (translation == pluralKey) {
      return '${translate(key, args: args)} ($count)';
    }

    return translation.replaceAll('{{count}}', count.toString());
  }

  /// Get currency formatted string
  String formatCurrency(double amount, {String? currencyCode}) {
    final code = currencyCode ?? _getDefaultCurrency();
    final format = NumberFormat.currency(
      locale: _currentLocale.toString(),
      symbol: _getCurrencySymbol(code),
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  /// Get percentage formatted string
  String formatPercentage(double value) {
    final format = NumberFormat.percentPattern(_currentLocale.toString());
    return format.format(value);
  }

  /// Get number formatted string
  String formatNumber(double value, {int? decimalPlaces}) {
    final format = NumberFormat.decimalPattern(_currentLocale.toString());
    if (decimalPlaces != null) {
      return format.format(value);
    }
    return format.format(value);
  }

  /// Get date formatted string
  String formatDate(DateTime date, {String? format}) {
    final dateFormat = _getDateFormat(format ?? 'medium');
    return dateFormat.format(date);
  }

  /// Get relative time string
  String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return translatePlural('time_years_ago', years);
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return translatePlural('time_months_ago', months);
    } else if (difference.inDays > 0) {
      return translatePlural('time_days_ago', difference.inDays);
    } else if (difference.inHours > 0) {
      return translatePlural('time_hours_ago', difference.inHours);
    } else if (difference.inMinutes > 0) {
      return translatePlural('time_minutes_ago', difference.inMinutes);
    } else {
      return translate('time_just_now');
    }
  }

  /// Check if current locale is RTL
  bool get isRTL => _getTextDirection() == ui.TextDirection.rtl;

  /// Get text direction for current locale
  ui.TextDirection getTextDirection() => _getTextDirection();

  /// Get locale-specific number formatting
  NumberFormat getNumberFormat(String pattern) {
    return NumberFormat(pattern, _currentLocale.toString());
  }

  /// Export user data with current locale
  Future<String> exportLocalizedData(Map<String, dynamic> data) async {
    final localizedData = <String, dynamic>{};

    // Add locale metadata
    localizedData['locale'] = {
      'code': currentLanguageCode,
      'name': _localeDefinitions[currentLanguageCode]?['name'],
      'export_date': formatDate(DateTime.now()),
    };

    // Localize data fields
    data.forEach((key, value) {
      localizedData[key] = _localizeDataValue(key, value);
    });

    return jsonEncode(localizedData);
  }

  // Private helper methods

  Future<void> _loadSavedLocale() async {
    try {
      final savedLocale = await SecureStorage.getEncryptedData(_localeKey);
      if (savedLocale != null && _localeDefinitions.containsKey(savedLocale)) {
        _currentLocale = Locale(savedLocale);
      } else {
        // Use device locale or fallback
        _currentLocale = _getDeviceLocale();
      }
    } catch (e) {
      _currentLocale = Locale(_fallbackLocale);
    }
  }

  void _loadSupportedLocales() {
    _supportedLocales.clear();
    _localeDefinitions.keys.forEach((code) {
      _supportedLocales[code] = Locale(code);
    });
  }

  Future<void> _loadLocalizationFiles() async {
    for (final localeCode in _localeDefinitions.keys) {
      try {
        final jsonString = await rootBundle.loadString('assets/locales/$localeCode.json');
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        _localizedStrings[localeCode] = Map<String, String>.from(jsonMap);
      } catch (e) {
        // If locale file doesn't exist, skip
        continue;
      }
    }
  }

  Future<void> _configureDateFormatting() async {
    await initializeDateFormatting(_currentLocale.toString(), null);
  }

  Locale _getDeviceLocale() {
    // In a real app, this would get the actual device locale
    // For now, return English
    return const Locale(_fallbackLocale);
  }

  String _getDefaultCurrency() {
    // Currency mapping based on locale
    final currencyMap = {
      'en': 'USD',
      'es': 'EUR',
      'fr': 'EUR',
      'de': 'EUR',
      'it': 'EUR',
      'pt': 'EUR',
      'ru': 'RUB',
      'ja': 'JPY',
      'ko': 'KRW',
      'zh': 'CNY',
      'ar': 'SAR',
      'hi': 'INR',
      'bn': 'BDT',
      'pa': 'INR',
      'te': 'INR',
      'mr': 'INR',
      'ta': 'INR',
      'ur': 'PKR',
      'gu': 'INR',
      'kn': 'INR',
    };

    return currencyMap[currentLanguageCode] ?? 'USD';
  }

  String _getCurrencySymbol(String currencyCode) {
    final symbolMap = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'INR': '₹',
      'RUB': '₽',
      'KRW': '₩',
    };

    return symbolMap[currencyCode] ?? currencyCode;
  }

  DateFormat _getDateFormat(String format) {
    switch (format) {
      case 'short':
        return DateFormat.yMd(_currentLocale.toString());
      case 'medium':
        return DateFormat.yMMMMd(_currentLocale.toString());
      case 'long':
        return DateFormat.yMMMMEEEEd(_currentLocale.toString());
      case 'time':
        return DateFormat.Hm(_currentLocale.toString());
      case 'datetime':
        return DateFormat.yMd(_currentLocale.toString()).add_Hm();
      default:
        return DateFormat.yMMMMd(_currentLocale.toString());
    }
  }

  ui.TextDirection _getTextDirection() {
    // RTL languages
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    // Use Flutter's TextDirection explicitly
    return rtlLanguages.contains(currentLanguageCode) 
        ? ui.TextDirection.rtl 
        : ui.TextDirection.ltr;
  }

  dynamic _localizeDataValue(String key, dynamic value) {
    if (value is String) {
      // Try to find a localized version
      final localizedKey = 'export_$key';
      final localized = translate(localizedKey);
      return localized != localizedKey ? localized : value;
    } else if (value is DateTime) {
      return formatDate(value);
    } else if (value is double && key.contains('amount')) {
      return formatCurrency(value);
    }
    return value;
  }

  void _notifyLocaleChange(Locale newLocale) {
    // This would notify the app to rebuild with new locale
    // Implementation would use provider/riverpod to notify listeners
  }
}

/// Localization delegate for Flutter
class FinWiseLocalizationsDelegate extends LocalizationsDelegate<FinWiseLocalizations> {
  const FinWiseLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return LocalizationService._localeDefinitions.containsKey(locale.languageCode);
  }

  @override
  Future<FinWiseLocalizations> load(Locale locale) async {
    await LocalizationService().initialize();
    await LocalizationService().changeLocale(locale.languageCode);
    return FinWiseLocalizations();
  }

  @override
  bool shouldReload(FinWiseLocalizationsDelegate old) => false;
}

/// Localization class for Flutter
class FinWiseLocalizations {
  static FinWiseLocalizations? of(BuildContext context) {
    return Localizations.of<FinWiseLocalizations>(context, FinWiseLocalizations);
  }

  static String translate(BuildContext context, String key, {Map<String, String>? args}) {
    return LocalizationService().translate(key, args: args);
  }

  static String translatePlural(BuildContext context, String key, int count, {Map<String, String>? args}) {
    return LocalizationService().translatePlural(key, count, args: args);
  }
}

/// Localized app configuration
class LocalizedAppConfig {
  static String get appName => LocalizationService().translate('app_name');
  static String get appDescription => LocalizationService().translate('app_description');

  static Map<String, String> appStoreMetadata(String platform) {
    final prefix = platform.toLowerCase();
    return {
      'title': LocalizationService().translate('${prefix}_app_title'),
      'description': LocalizationService().translate('${prefix}_app_description'),
      'keywords': LocalizationService().translate('${prefix}_app_keywords'),
      'privacy_policy': LocalizationService().translate('${prefix}_privacy_policy_url'),
      'terms_of_service': LocalizationService().translate('${prefix}_terms_url'),
    };
  }
}
