// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appSlogan => 'Secure and open access';

  @override
  String get languageName => 'فارسی';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get findingRoute => 'Finding a route';

  @override
  String get disconnecting => 'Disconnecting';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String connectWait(String seconds) {
    return 'Wait $seconds seconds to connect';
  }

  @override
  String get tapToConnect => 'Tap to connect';

  @override
  String get checkingRoute => 'Checking route. Tap to cancel.';

  @override
  String get tunnelActive => 'Tunnel is active';

  @override
  String get viewLogs => 'View logs';

  @override
  String get logs => 'Logs';

  @override
  String get copy => 'Copy';

  @override
  String get logsCopied => 'Logs copied';

  @override
  String get noLogs => 'No logs yet. They will appear here after connecting.';

  @override
  String get vpnMode => 'VPN mode';

  @override
  String get allAppsTunnel => 'All apps use the tunnel.';

  @override
  String get proxyOnly => 'SOCKS5 proxy only at 127.0.0.1:1819.';

  @override
  String get connectionSettings => 'Connection settings';

  @override
  String get scanMode => 'Scan mode';

  @override
  String get obfuscation => 'Obfuscation (noize)';

  @override
  String get ipVersion => 'IP version for scanning';

  @override
  String get http2Title => 'HTTP/2 instead of HTTP/3';

  @override
  String get http2Hint => 'For networks that block UDP or QUIC.';

  @override
  String get connectionProtocol => 'Connection protocol';

  @override
  String activeProtocol(String name) {
    return 'Active: $name';
  }

  @override
  String get tunnelIpDetecting => 'Detecting tunnel IP…';

  @override
  String get tunnelExitIp => 'Tunnel exit IP';

  @override
  String get currentIpNoTunnel => 'Your current IP (no tunnel)';

  @override
  String get ipDetecting => 'Detecting IP…';

  @override
  String get ipNotDetected => 'Could not detect IP. Retry';

  @override
  String runFailed(String error) {
    return 'Could not start: $error';
  }

  @override
  String get nativeMissing =>
      'Native component is not registered. Run tools/android/apply_overlay.py.';

  @override
  String get anyCountry => 'Any country';

  @override
  String get connectionShape => 'Connection shape';

  @override
  String get cdnHint =>
      'CDN: through a CDN, for networks that block other traffic. Direct: without this cover.';

  @override
  String get exitCountry => 'Exit country';

  @override
  String get countryRetryHint =>
      'If the selected country does not connect, try Any country.';

  @override
  String scanSummary(String scan, String noise, String ip) {
    return 'Scan $scan, obfuscation $noise, $ip';
  }

  @override
  String psiphonSummary(String shape, String country) {
    return 'Shape $shape, exit $country';
  }

  @override
  String get protocolHintMasque =>
      'Looks like normal web traffic. Recommended.';

  @override
  String get protocolHintWg =>
      'Light and fast. For networks that only block addresses.';

  @override
  String get protocolHintGool =>
      'WireGuard runs inside a MASQUE tunnel to provide a non-Iran-IP.';

  @override
  String get protocolHintPsiphon =>
      'Direct through Psiphon, without WARP. First connection can take up to 3 minutes.';

  @override
  String get shapeAuto => 'Automatic';

  @override
  String get shapeDirect => 'Direct';

  @override
  String get unknown => 'Unknown';

  @override
  String get ipCopied => 'IP copied';

  @override
  String get connect => 'Connect';

  @override
  String get cancelConnection => 'Cancel connection';

  @override
  String get languageTooltip => 'Language';

  @override
  String get dualIpVersion => 'Both';

  @override
  String get shapeCdn => 'CDN';

  @override
  String get switchToLight => 'Switch to light mode';

  @override
  String get switchToDark => 'Switch to dark mode';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get download => 'Download';

  @override
  String get downloadApk => 'Download';

  @override
  String get sourceCode => 'Source code';

  @override
  String get contact => 'Contact';

  @override
  String get telegram => 'Telegram';
}
