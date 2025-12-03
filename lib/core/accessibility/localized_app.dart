import 'package:finwise/core/accessibility/accessibility_service.dart';
import 'package:finwise/core/localization/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Localized and accessible app wrapper
/// Provides WCAG 2.1 AA compliance and full internationalization
class LocalizedAccessibleApp extends StatefulWidget {
  final Widget child;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final ThemeMode themeMode;

  const LocalizedAccessibleApp({
    super.key,
    required this.child,
    required this.lightTheme,
    required this.darkTheme,
    required this.themeMode,
  });

  @override
  State<LocalizedAccessibleApp> createState() => _LocalizedAccessibleAppState();
}

class _LocalizedAccessibleAppState extends State<LocalizedAccessibleApp> {
  late LocalizationService _localizationService;
  late AccessibilityService _accessibilityService;

  @override
  void initState() {
    super.initState();
    _localizationService = LocalizationService();
    _accessibilityService = AccessibilityService();

    // Initialize services
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _localizationService.initialize();
    await _accessibilityService.initialize();

    // Rebuild app with initialized services
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessibilityConfigWidget(
      child: MaterialApp(
        title: LocalizationService().translate('app_name'),
        theme: widget.lightTheme,
        darkTheme: widget.darkTheme,
        themeMode: widget.themeMode,

        // Localization
        locale: _localizationService.currentLocale,
        supportedLocales: _localizationService.supportedLocales,
        localizationsDelegates: [
          FinWiseLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          // Try to match exact locale
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode &&
                supportedLocale.countryCode == locale?.countryCode) {
              return supportedLocale;
            }
          }

          // Try to match language only
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }

          // Return first supported locale as fallback
          return supportedLocales.first;
        },

        // Accessibility
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: _accessibilityService.textScaleFactor,
            ),
            child: Directionality(
              textDirection: _localizationService.getTextDirection(),
              child: child!,
            ),
          );
        },

        home: widget.child,
      ),
    );
  }
}

/// Localized and accessible scaffold wrapper
class LocalizedAccessibleScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? drawerScrimColor;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final Widget? drawer;
  final Widget? endDrawer;
  final String? restorationId;

  const LocalizedAccessibleScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.drawer,
    this.endDrawer,
    this.restorationId,
  });

  @override
  Widget build(BuildContext context) {
    final accessibility = AccessibilityService();

    return Scaffold(
      appBar: appBar,
      body: body != null ? Semantics(
        label: 'Main content',
        child: body,
      ) : null,
      floatingActionButton: floatingActionButton != null ? AccessibleButton(
        child: floatingActionButton!,
        onPressed: null, // Will be handled by the FAB itself
        semanticLabel: 'Floating action button',
        hint: 'Tap to perform primary action',
      ) : null,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      drawer: drawer,
      endDrawer: endDrawer,
      restorationId: restorationId,
    );
  }
}

/// Localized text widget with accessibility support
class LocalizedText extends StatelessWidget {
  final String key;
  final Map<String, String>? args;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  const LocalizedText(
    this.key, {
    super.key,
    this.args,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
  });

  @override
  Widget build(BuildContext context) {
    final localization = LocalizationService();
    final accessibility = AccessibilityService();

    final translatedText = localization.translate(key, args: args);
    final accessibleStyle = accessibility.getAccessibleTextStyle(context, baseStyle: style);

    return AccessibleWidget(
      semanticLabel: semanticsLabel,
      child: Text(
        translatedText,
        style: accessibleStyle,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection ?? localization.getTextDirection(),
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaleFactor: textScaleFactor,
        maxLines: maxLines,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      ),
    );
  }
}

/// Localized plural text widget
class LocalizedPluralText extends StatelessWidget {
  final String key;
  final int count;
  final Map<String, String>? args;
  final TextStyle? style;

  const LocalizedPluralText(
    this.key,
    this.count, {
    super.key,
    this.args,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final localization = LocalizationService();
    final accessibility = AccessibilityService();

    final translatedText = localization.translatePlural(key, count, args: args);
    final accessibleStyle = accessibility.getAccessibleTextStyle(context, baseStyle: style);

    return AccessibleWidget(
      semanticLabel: '$translatedText',
      child: Text(
        translatedText,
        style: accessibleStyle,
      ),
    );
  }
}

/// Accessible form field wrapper
class AccessibleFormField extends StatelessWidget {
  final String labelKey;
  final String? hintKey;
  final String? errorText;
  final bool obscureText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool autofocus;

  const AccessibleFormField({
    super.key,
    required this.labelKey,
    this.hintKey,
    this.errorText,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final localization = LocalizationService();
    final accessibility = AccessibilityService();

    return AccessibleTextField(
      controller: controller,
      labelText: localization.translate(labelKey),
      hintText: hintKey != null ? localization.translate(hintKey!) : null,
      semanticLabel: localization.translate(labelKey),
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      autofocus: autofocus,
    );
  }
}

/// Language switcher widget
class LanguageSwitcher extends StatefulWidget {
  final double iconSize;
  final TextStyle? textStyle;

  const LanguageSwitcher({
    super.key,
    this.iconSize = 24.0,
    this.textStyle,
  });

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  late LocalizationService _localizationService;

  @override
  void initState() {
    super.initState();
    _localizationService = LocalizationService();
  }

  @override
  Widget build(BuildContext context) {
    final localeInfo = _localizationService.supportedLocaleInfo;

    return PopupMenuButton<String>(
      onSelected: (languageCode) async {
        await _localizationService.changeLocale(languageCode);
        setState(() {}); // Rebuild to show new language
      },
      itemBuilder: (context) => localeInfo.map((locale) {
        return PopupMenuItem<String>(
          value: locale['code'],
          child: Row(
            children: [
              Text(locale['flag']!, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                locale['nativeName']!,
                style: widget.textStyle,
              ),
              if (locale['isCurrent'] == true) ...[
                const SizedBox(width: 8),
                Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
        );
      }).toList(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _localizationService.currentLocale.languageCode.toUpperCase(),
              style: widget.textStyle ?? Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 4),
            Icon(Icons.language, size: widget.iconSize),
          ],
        ),
      ),
    );
  }
}

/// Accessibility settings widget
class AccessibilitySettingsWidget extends StatefulWidget {
  const AccessibilitySettingsWidget({super.key});

  @override
  State<AccessibilitySettingsWidget> createState() => _AccessibilitySettingsWidgetState();
}

class _AccessibilitySettingsWidgetState extends State<AccessibilitySettingsWidget> {
  late AccessibilityService _accessibilityService;

  @override
  void initState() {
    super.initState();
    _accessibilityService = AccessibilityService();
  }

  @override
  Widget build(BuildContext context) {
    final localization = LocalizationService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          'accessibility.accessibility_settings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),

        // High contrast toggle
        SwitchListTile(
          title: LocalizedText('accessibility.high_contrast'),
          value: _accessibilityService.highContrastEnabled,
          onChanged: (value) async {
            await _accessibilityService.updateSettings(highContrast: value);
            setState(() {});
          },
        ),

        // Large text toggle
        SwitchListTile(
          title: LocalizedText('accessibility.large_text'),
          value: _accessibilityService.largeTextEnabled,
          onChanged: (value) async {
            await _accessibilityService.updateSettings(largeText: value);
            setState(() {});
          },
        ),

        // Reduced motion toggle
        SwitchListTile(
          title: LocalizedText('accessibility.reduced_motion'),
          value: _accessibilityService.reducedMotionEnabled,
          onChanged: (value) async {
            await _accessibilityService.updateSettings(reducedMotion: value);
            setState(() {});
          },
        ),

        // Text scale slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              LocalizedText('accessibility.text_scale'),
              Expanded(
                child: Slider(
                  value: _accessibilityService.textScaleFactor,
                  min: 0.8,
                  max: 2.0,
                  divisions: 12,
                  label: _accessibilityService.textScaleFactor.toStringAsFixed(1),
                  onChanged: (value) async {
                    await _accessibilityService.updateSettings(textScale: value);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),

        // Touch target scale slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              LocalizedText('accessibility.touch_targets'),
              Expanded(
                child: Slider(
                  value: _accessibilityService.touchTargetScale,
                  min: 0.8,
                  max: 2.0,
                  divisions: 12,
                  label: _accessibilityService.touchTargetScale.toStringAsFixed(1),
                  onChanged: (value) async {
                    await _accessibilityService.updateSettings(touchTargetScale: value);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // WCAG compliance check
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  'WCAG 2.1 AA Compliance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._accessibilityService.checkWCAGCompliance().entries.map(
                  (entry) => Row(
                    children: [
                      Icon(
                        entry.value ? Icons.check_circle : Icons.cancel,
                        color: entry.value ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.key.replaceAll('_', ' ')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Recommendations
        if (_accessibilityService.getAccessibilityRecommendations().isNotEmpty) ...[
          LocalizedText(
            'Recommendations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._accessibilityService.getAccessibilityRecommendations().map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(recommendation)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
