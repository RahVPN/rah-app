// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appSlogan => 'اتصال امن و آزاد';

  @override
  String get languageName => 'English';

  @override
  String get connected => 'وصل است';

  @override
  String get disconnected => 'قطع است';

  @override
  String get findingRoute => 'در حال یافتن مسیر';

  @override
  String get disconnecting => 'در حال قطع';

  @override
  String get connectionFailed => 'اتصال برقرار نشد';

  @override
  String connectWait(String seconds) {
    return 'برای اتصال $seconds ثانیه صبر کن';
  }

  @override
  String get tapToConnect => 'برای اتصال لمس کن';

  @override
  String get checkingRoute => 'مسیر بررسی می‌شود. برای لغو لمس کن.';

  @override
  String get tunnelActive => 'تونل فعال است';

  @override
  String get viewLogs => 'مشاهده گزارش';

  @override
  String get logs => 'گزارش';

  @override
  String get copy => 'کپی';

  @override
  String get logsCopied => 'گزارش کپی شد';

  @override
  String get noLogs => 'هنوز گزارشی نیست. بعد از شروع اتصال اینجا پر می‌شود.';

  @override
  String get vpnMode => 'حالت VPN';

  @override
  String get allAppsTunnel => 'همه برنامه‌ها از تونل رد می‌شوند.';

  @override
  String get proxyOnly => 'فقط پروکسی SOCKS5 روی 127.0.0.1:1819.';

  @override
  String get connectionSettings => 'تنظیمات اتصال';

  @override
  String get scanMode => 'حالت اسکن';

  @override
  String get obfuscation => 'مبهم‌سازی (noize)';

  @override
  String get ipVersion => 'نسخه IP برای اسکن';

  @override
  String get http2Title => 'HTTP/2 به‌جای HTTP/3';

  @override
  String get http2Hint => 'برای شبکه‌هایی که UDP یا QUIC را مسدود می‌کنند.';

  @override
  String get connectionProtocol => 'پروتکل اتصال';

  @override
  String activeProtocol(String name) {
    return 'فعال: $name';
  }

  @override
  String get tunnelIpDetecting => 'در حال تشخیص IP تونل…';

  @override
  String get tunnelExitIp => 'IP خروجی تونل';

  @override
  String get currentIpNoTunnel => 'IP فعلی شما (بدون تونل)';

  @override
  String get ipDetecting => 'در حال تشخیص IP…';

  @override
  String get ipNotDetected => 'IP تشخیص داده نشد. دوباره تلاش کن';

  @override
  String runFailed(String error) {
    return 'اجرا نشد: $error';
  }

  @override
  String get nativeMissing =>
      'بخش native ثبت نشده. tools/android/apply_overlay.py را اجرا کن.';

  @override
  String get anyCountry => 'هر کشور';

  @override
  String get connectionShape => 'شکل اتصال';

  @override
  String get cdnHint =>
      'CDN: فقط از پشت CDN، برای شبکه‌هایی که بقیه را می‌بندند. مستقیم: بدون این پوشش.';

  @override
  String get exitCountry => 'کشور خروجی';

  @override
  String get countryRetryHint =>
      'اگر با کشور انتخابی وصل نشد، «هر کشور» را امتحان کن.';

  @override
  String scanSummary(String scan, String noise, String ip) {
    return 'اسکن $scan، مبهم‌سازی $noise، $ip';
  }

  @override
  String psiphonSummary(String shape, String country) {
    return 'شکل $shape، خروجی $country';
  }

  @override
  String get protocolHintMasque => 'شبیه ترافیک عادی وب است. انتخاب پیشنهادی.';

  @override
  String get protocolHintWg =>
      'سبک و سریع. برای شبکه‌هایی که فقط آدرس‌ها را مسدود می‌کنند.';

  @override
  String get protocolHintGool =>
      'WireGuard داخل تونل MASQUE رد می‌شود تا IP غیرایران بگیرید.';

  @override
  String get protocolHintPsiphon =>
      'بدون WARP، مستقیم از شبکه Psiphon. اتصال اول ممکن است تا ۳ دقیقه طول بکشد.';

  @override
  String get shapeAuto => 'خودکار';

  @override
  String get shapeDirect => 'مستقیم';

  @override
  String get unknown => 'نامشخص';

  @override
  String get ipCopied => 'IP کپی شد';

  @override
  String get connect => 'اتصال';

  @override
  String get cancelConnection => 'لغو اتصال';

  @override
  String get languageTooltip => 'زبان';

  @override
  String get dualIpVersion => 'هر دو';

  @override
  String get shapeCdn => 'CDN';

  @override
  String get switchToLight => 'تغییر به حالت روشن';

  @override
  String get switchToDark => 'تغییر به حالت تاریک';

  @override
  String get about => 'درباره برنامه';

  @override
  String get version => 'نسخه';

  @override
  String get download => 'دانلود';

  @override
  String get downloadApk => 'دانلود  ';

  @override
  String get sourceCode => 'کد منبع';

  @override
  String get contact => 'راه‌های ارتباطی';

  @override
  String get telegram => 'تلگرام';
}
