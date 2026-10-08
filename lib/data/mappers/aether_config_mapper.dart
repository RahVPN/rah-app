
import 'package:rah_app/domain/entities/aether_config.dart';

class AetherConfigMapper {
  const AetherConfigMapper._();

  static Map<String, Object> toMap(AetherConfig config) => {
    'protocol': config.protocol,
    'scan': config.scan,
    'noize': config.noize,
    'ip': config.ip,
    'http2': config.http2,
    'vpn': config.vpn,
    'shape': config.psiphonShape,
    'region': config.psiphonRegion,
  };

  static AetherConfig fromMap(Map<String, dynamic> map) {
    String pick(String key, Set<String> allowed, String fallback) {
      final value = map[key];
      return value is String && allowed.contains(value) ? value : fallback;
    }

    final protocol = pick('protocol', {
      'masque',
      'wg',
      'gool',
      'psiphon',
    }, 'masque');
    return AetherConfig(
      protocol: protocol,
      scan: pick('scan', {
        'turbo',
        'balanced',
        'thorough',
        'stealth',
        'ironclad',
      }, 'balanced'),
      noize: pick(
        'noize',
        protocol == 'masque'
            ? {'firewall', 'gfw', 'off'}
            : {'balanced', 'aggressive', 'light', 'off'},
        protocol == 'masque' ? 'firewall' : 'balanced',
      ),
      ip: pick('ip', {'4', '6', 'dual'}, '4'),
      http2: map['http2'] is bool ? map['http2'] as bool : false,
      vpn: map['vpn'] is bool ? map['vpn'] as bool : true,
      psiphonShape: pick('shape', {'auto', 'cdn', 'direct'}, 'auto'),
      psiphonRegion: pick('region', {
        '',
        'DE',
        'NL',
        'GB',
        'US',
        'CA',
        'FR',
        'SE',
        'CH',
        'FI',
      }, ''),
    );
  }
}
