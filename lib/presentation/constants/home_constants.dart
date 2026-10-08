abstract final class HomeConstants {
  static const masqueNoize = ['firewall', 'gfw', 'off'];
  static const wireGuardNoize = ['balanced', 'aggressive', 'light', 'off'];
  static const scans = ['turbo', 'balanced', 'thorough', 'stealth', 'ironclad'];
  // Protocol identifiers and display names are stable domain/UI values.
  static const protocolNames = {
    'masque': 'MASQUE',
    'wg': 'WireGuard',
    'gool': 'Gool',
    'psiphon': 'Psiphon',
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
