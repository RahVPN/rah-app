abstract final class HomeConstants {
  static const masqueNoize = ['firewall', 'gfw', 'off'];
  static const wireGuardNoize = ['balanced', 'aggressive', 'light', 'off'];
  static const scans = ['turbo', 'balanced', 'thorough', 'stealth', 'ironclad'];
  static const ipVersions = {'4': 'IPv4', '6': 'IPv6', 'dual': 'هر دو'};

  static const protocolHints = {
    'masque': 'شبیه ترافیک عادی وب است. انتخاب پیشنهادی.',
    'wg': 'سبک و سریع. برای شبکه‌هایی که فقط آدرس‌ها را مسدود می‌کنند.',
    'gool': 'WireGuard داخل تونل MASQUE رد می‌شوند تا IP غیرایرانی بگیرید.',
    'psiphon':
        'بدون WARP، مستقیم از شبکه Psiphon. اتصال اول ممکن است تا ۳ دقیقه طول بکشد.',
  };

  static const protocolNames = {
    'masque': 'MASQUE',
    'wg': 'WireGuard',
    'gool': 'Gool',
    'psiphon': 'Psiphon',
  };

  static const psiphonShapes = {
    'auto': 'خودکار',
    'cdn': 'CDN',
    'direct': 'مستقیم',
  };
  static const psiphonRegions = [
    'DE',
    'NL',
    'GB',
    'US',
    'CA',
    'FR',
    'SE',
    'CH',
    'FI',
  ];
  static const psiphonHttpProxy = '127.0.0.1:1820';
}
