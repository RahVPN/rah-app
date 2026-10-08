class AetherConfig {
  const AetherConfig({
    this.protocol = 'masque',
    this.scan = 'balanced',
    this.noize = 'firewall',
    this.ip = '4',
    this.http2 = false,
    this.vpn = true,
    this.psiphonShape = 'auto',
    this.psiphonRegion = '',
  });

  final String protocol;
  final String scan;
  final String noize;
  final String ip;
  final bool http2;
  final bool vpn;
  final String psiphonShape;
  final String psiphonRegion;

  AetherConfig copyWith({
    String? protocol,
    String? scan,
    String? noize,
    String? ip,
    bool? http2,
    bool? vpn,
    String? psiphonShape,
    String? psiphonRegion,
  }) => AetherConfig(
    protocol: protocol ?? this.protocol,
    scan: scan ?? this.scan,
    noize: noize ?? this.noize,
    ip: ip ?? this.ip,
    http2: http2 ?? this.http2,
    vpn: vpn ?? this.vpn,
    psiphonShape: psiphonShape ?? this.psiphonShape,
    psiphonRegion: psiphonRegion ?? this.psiphonRegion,
  );
}
