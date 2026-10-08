import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Secure and open access'**
  String get appSlogan;

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'فارسی'**
  String get languageName;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @findingRoute.
  ///
  /// In en, this message translates to:
  /// **'Finding a route'**
  String get findingRoute;

  /// No description provided for @disconnecting.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting'**
  String get disconnecting;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @connectWait.
  ///
  /// In en, this message translates to:
  /// **'Wait {seconds} seconds to connect'**
  String connectWait(String seconds);

  /// No description provided for @tapToConnect.
  ///
  /// In en, this message translates to:
  /// **'Tap to connect'**
  String get tapToConnect;

  /// No description provided for @checkingRoute.
  ///
  /// In en, this message translates to:
  /// **'Checking route. Tap to cancel.'**
  String get checkingRoute;

  /// No description provided for @tunnelActive.
  ///
  /// In en, this message translates to:
  /// **'Tunnel is active'**
  String get tunnelActive;

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'View logs'**
  String get viewLogs;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @logsCopied.
  ///
  /// In en, this message translates to:
  /// **'Logs copied'**
  String get logsCopied;

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs yet. They will appear here after connecting.'**
  String get noLogs;

  /// No description provided for @vpnMode.
  ///
  /// In en, this message translates to:
  /// **'VPN mode'**
  String get vpnMode;

  /// No description provided for @allAppsTunnel.
  ///
  /// In en, this message translates to:
  /// **'All apps use the tunnel.'**
  String get allAppsTunnel;

  /// No description provided for @proxyOnly.
  ///
  /// In en, this message translates to:
  /// **'SOCKS5 proxy only at 127.0.0.1:1819.'**
  String get proxyOnly;

  /// No description provided for @connectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Connection settings'**
  String get connectionSettings;

  /// No description provided for @scanMode.
  ///
  /// In en, this message translates to:
  /// **'Scan mode'**
  String get scanMode;

  /// No description provided for @obfuscation.
  ///
  /// In en, this message translates to:
  /// **'Obfuscation (noize)'**
  String get obfuscation;

  /// No description provided for @ipVersion.
  ///
  /// In en, this message translates to:
  /// **'IP version for scanning'**
  String get ipVersion;

  /// No description provided for @http2Title.
  ///
  /// In en, this message translates to:
  /// **'HTTP/2 instead of HTTP/3'**
  String get http2Title;

  /// No description provided for @http2Hint.
  ///
  /// In en, this message translates to:
  /// **'For networks that block UDP or QUIC.'**
  String get http2Hint;

  /// No description provided for @connectionProtocol.
  ///
  /// In en, this message translates to:
  /// **'Connection protocol'**
  String get connectionProtocol;

  /// No description provided for @activeProtocol.
  ///
  /// In en, this message translates to:
  /// **'Active: {name}'**
  String activeProtocol(String name);

  /// No description provided for @tunnelIpDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting tunnel IP…'**
  String get tunnelIpDetecting;

  /// No description provided for @tunnelExitIp.
  ///
  /// In en, this message translates to:
  /// **'Tunnel exit IP'**
  String get tunnelExitIp;

  /// No description provided for @currentIpNoTunnel.
  ///
  /// In en, this message translates to:
  /// **'Your current IP (no tunnel)'**
  String get currentIpNoTunnel;

  /// No description provided for @ipDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting IP…'**
  String get ipDetecting;

  /// No description provided for @ipNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Could not detect IP. Retry'**
  String get ipNotDetected;

  /// No description provided for @runFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start: {error}'**
  String runFailed(String error);

  /// No description provided for @nativeMissing.
  ///
  /// In en, this message translates to:
  /// **'Native component is not registered. Run tools/android/apply_overlay.py.'**
  String get nativeMissing;

  /// No description provided for @anyCountry.
  ///
  /// In en, this message translates to:
  /// **'Any country'**
  String get anyCountry;

  /// No description provided for @connectionShape.
  ///
  /// In en, this message translates to:
  /// **'Connection shape'**
  String get connectionShape;

  /// No description provided for @cdnHint.
  ///
  /// In en, this message translates to:
  /// **'CDN: through a CDN, for networks that block other traffic. Direct: without this cover.'**
  String get cdnHint;

  /// No description provided for @exitCountry.
  ///
  /// In en, this message translates to:
  /// **'Exit country'**
  String get exitCountry;

  /// No description provided for @countryRetryHint.
  ///
  /// In en, this message translates to:
  /// **'If the selected country does not connect, try Any country.'**
  String get countryRetryHint;

  /// No description provided for @scanSummary.
  ///
  /// In en, this message translates to:
  /// **'Scan {scan}, obfuscation {noise}, {ip}'**
  String scanSummary(String scan, String noise, String ip);

  /// No description provided for @psiphonSummary.
  ///
  /// In en, this message translates to:
  /// **'Shape {shape}, exit {country}'**
  String psiphonSummary(String shape, String country);

  /// No description provided for @protocolHintMasque.
  ///
  /// In en, this message translates to:
  /// **'Looks like normal web traffic. Recommended.'**
  String get protocolHintMasque;

  /// No description provided for @protocolHintWg.
  ///
  /// In en, this message translates to:
  /// **'Light and fast. For networks that only block addresses.'**
  String get protocolHintWg;

  /// No description provided for @protocolHintGool.
  ///
  /// In en, this message translates to:
  /// **'WireGuard runs inside a MASQUE tunnel to provide a non-Iran-IP.'**
  String get protocolHintGool;

  /// No description provided for @protocolHintPsiphon.
  ///
  /// In en, this message translates to:
  /// **'Direct through Psiphon, without WARP. First connection can take up to 3 minutes.'**
  String get protocolHintPsiphon;

  /// No description provided for @shapeAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get shapeAuto;

  /// No description provided for @shapeDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get shapeDirect;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @ipCopied.
  ///
  /// In en, this message translates to:
  /// **'IP copied'**
  String get ipCopied;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @cancelConnection.
  ///
  /// In en, this message translates to:
  /// **'Cancel connection'**
  String get cancelConnection;

  /// No description provided for @languageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTooltip;

  /// No description provided for @dualIpVersion.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get dualIpVersion;

  /// No description provided for @shapeCdn.
  ///
  /// In en, this message translates to:
  /// **'CDN'**
  String get shapeCdn;

  /// No description provided for @switchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get switchToLight;

  /// No description provided for @switchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get switchToDark;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloadApk.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadApk;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @telegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get telegram;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
