import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rah_app/data/datasources/aether_data_source.dart';
import 'package:rah_app/domain/entities/aether_config.dart';
import 'package:rah_app/domain/entities/aether_state.dart';

/// Linux: runs Aether and, when requested, connects its SOCKS5 proxy to a system TUN.
class AetherProcessDataSource implements AetherDataSource {
  AetherProcessDataSource() {
    // A closed terminal / `kill` should not leave an orphaned core (and its Psiphon child) behind.
    for (final sig in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
      _signalSubs.add(
        sig.watch().listen((_) async {
          await stop();
          exit(0);
        }),
      );
    }
  }

  static const _socksHost = '127.0.0.1';
  static const _socksPort = 1819;
  static const _psiphonHttpPort = 1820;
  static const _tunName = 'rah0';
  static const _socketMark = '1819';
  static const _readyTimeout = Duration(minutes: 10);

  final _events = StreamController<AetherEvent>.broadcast();
  final _logs = StreamController<String>.broadcast();
  final _signalSubs = <StreamSubscription<ProcessSignal>>[];

  AetherState _state = AetherState.idle;
  Process? _process;
  File? _tunStopRequest;
  File? _psiphonReadyFile;

  /// Bumped on every start/stop so a stale supervisor can tell it was replaced.
  int _generation = 0;
  bool _psiphonReady = false;

  @override
  Stream<AetherEvent> get states => _events.stream;

  @override
  Stream<String> get logs => _logs.stream;

  @override
  Future<AetherState> currentState() async => _state;

  void _emit(AetherState state, [String? message]) {
    _state = state;
    if (!_events.isClosed) {
      _events.add(AetherEvent(state: state, message: message));
    }
  }

  void _recordLog(String line) {
    if (!_logs.isClosed) _logs.add(line);
    try {
      final file = File('${_stateDir().path}/rahvpn.log');
      file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } on Object {
      // Logging must not interrupt a tunnel if storage is unavailable.
    }
  }

  // ------------------------------------------------------------------ locations

  /// Where `aether` and `pt/psiphon-tunnel-core` live.
  /// Order: $RAH_AETHER_DIR, <bundle>/aether (release layout), ./linux/aether (flutter run).
  static Directory? _coreDir() {
    final candidates = <String>[
      if (Platform.environment['RAH_AETHER_DIR'] case final d?
          when d.isNotEmpty)
        d,
      '${File(Platform.resolvedExecutable).parent.path}/aether',
      '${Directory.current.path}/linux/aether',
    ];
    for (final c in candidates) {
      if (File('$c/aether').existsSync()) return Directory(c);
    }
    return null;
  }

  /// Config, WARP identity and Psiphon data. Survives updates; deleting it registers a new WARP device.
  static Directory _stateDir() {
    final env = Platform.environment;
    final base =
        (env['XDG_DATA_HOME'] != null && env['XDG_DATA_HOME']!.isNotEmpty)
        ? env['XDG_DATA_HOME']!
        : '${env['HOME'] ?? Directory.systemTemp.path}/.local/share';
    return Directory('$base/rahvpn')..createSync(recursive: true);
  }

  // ------------------------------------------------------------------ start / stop

  @override
  Future<void> start(AetherConfig config) async {
    if (_process != null || _state == AetherState.starting) return;
    final gen = ++_generation;
    _emit(AetherState.starting);
    unawaited(_supervise(config, gen));
  }

  @override
  Future<void> stop() async {
    if (_process == null && _state != AetherState.starting) {
      _emit(AetherState.idle);
      return;
    }
    _emit(AetherState.stopping);
    _generation++;
    await _kill();
    _emit(AetherState.idle);
  }

  Future<void> _kill() async {
    final stopRequest = _tunStopRequest;
    _tunStopRequest = null;
    _psiphonReadyFile = null;
    if (stopRequest != null) {
      try {
        stopRequest.writeAsStringSync('stop\n');
      } on Object {
        // Fall back to signaling pkexec below if the supervisor is already gone.
      }
    }
    final p = _process;
    _process = null;
    if (p == null) return;
    if (stopRequest != null) {
      try {
        await p.exitCode.timeout(const Duration(seconds: 15));
        return;
      } on TimeoutException {
        // Fallback if pkexec did not relay the control-file stop request.
      }
    }
    // SIGTERM first: Aether stops its embedded Psiphon child on a clean exit.
    p.kill(ProcessSignal.sigterm);
    try {
      await p.exitCode.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      p.kill(ProcessSignal.sigkill);
      await p.exitCode;
    }
  }

  // ------------------------------------------------------------------ supervisor

  Future<void> _supervise(AetherConfig cfg, int gen) async {
    try {
      _recordLog(
        'connection mode: ${cfg.vpn ? 'system TUN' : 'proxy-only'}, protocol: ${cfg.protocol}',
      );
      final dir = _coreDir();
      if (dir == null) {
        throw StateError(
          'aether binary not found (run tools/linux/fetch_deps_linux.sh, or set RAH_AETHER_DIR)',
        );
      }
      if (cfg.vpn) {
        if (!File('${dir.path}/hev-socks5-tunnel').existsSync()) {
          throw StateError(
            'hev-socks5-tunnel is missing. Run bash tools/linux/fetch_deps_linux.sh, then restart the app.',
          );
        }
        if (_routeHelper(dir) == null) {
          throw StateError(
            'Linux TUN route helper is missing. Run bash tools/linux/fetch_deps_linux.sh, then restart the app.',
          );
        }
        if (_tunSupervisor(dir) == null) {
          throw StateError(
            'Linux TUN supervisor is missing. Run bash tools/linux/fetch_deps_linux.sh, then restart the app.',
          );
        }
        if (!File('/usr/bin/setpriv').existsSync() &&
            !File('/bin/setpriv').existsSync()) {
          throw StateError(
            'setpriv is required for Linux TUN mode (install util-linux).',
          );
        }
      }
      final psiphon = cfg.protocol == 'psiphon';
      if (cfg.vpn && psiphon) {
        _recordLog(
          'Psiphon TUN: DNS uses hev mapdns; SOCKS5 has no UDP relay, so UDP applications may not work.',
        );
      }
      final psiBin = File('${dir.path}/pt/psiphon-tunnel-core');
      if (psiphon && !psiBin.existsSync()) {
        throw StateError(
          '${psiBin.path} not found (run tools/linux/fetch_deps_linux.sh)',
        );
      }
      if (!cfg.vpn && await _socksOpen()) {
        throw StateError(
          'SOCKS5 port $_socksPort is already in use while Linux VPN/TUN mode is off; turn on VPN mode or stop the other Aether instance.',
        );
      }

      final state = _stateDir();
      _psiphonReady = false;
      // The WARP API hostname cannot be resolved through the marked socket. Resolve it
      // while the normal default route is still active and pass its IP to Aether.
      final enrollAddress = cfg.vpn && !psiphon
          ? await _resolveEnrollAddress(cfg.ip)
          : null;
      final env = <String, String>{
        'PATH': Platform.environment['PATH'] ?? '/usr/bin:/bin',
        'LANG': Platform.environment['LANG'] ?? 'C.UTF-8',
        'HOME': state.path,
        'AETHER_CONFIG': '${state.path}/aether.toml',
        'AETHER_MASQUE_CONFIG': '${state.path}/aether-masque.toml',
        'AETHER_SOCKS': '$_socksHost:$_socksPort',
        if (cfg.vpn) 'AETHER_MARK': _socketMark,
        if (enrollAddress != null) 'AETHER_ENROLL_ADDRESS': enrollAddress,
        if (psiphon) ...{
          // No WARP tunnel: the SOCKS5 port is Psiphon itself.
          'AETHER_PSIPHON': 'only',
          'AETHER_PSIPHON_BIN': psiBin.path,
          'AETHER_PSIPHON_READY_SECS': '180',
          'AETHER_PSIPHON_DIR': '${state.path}/psiphon',
          'AETHER_PSIPHON_HTTP': '$_socksHost:$_psiphonHttpPort',
          'AETHER_PSIPHON_MODE': cfg.psiphonShape,
          'AETHER_PSIPHON_CONFIG': _writePsiphonOverride(state).path,
          if (cfg.psiphonRegion.isNotEmpty)
            'AETHER_PSIPHON_REGION': cfg.psiphonRegion,
        } else ...{
          'AETHER_PROTOCOL': cfg.protocol,
          // Aether 2.3 gool carries WireGuard inside MASQUE. Reject Iranian exits.
          if (cfg.protocol == 'gool') 'AETHER_EXIT_LOC': '!IR',
          'AETHER_SCAN': cfg.scan,
          'AETHER_NOIZE': cfg.noize,
          'AETHER_IP': cfg.ip,
          'AETHER_QUICK_RECONNECT': '1',
          if ((cfg.protocol == 'masque' || cfg.protocol == 'gool') && cfg.http2)
            'AETHER_MASQUE_HTTP2': '1',
        },
      };

      final corePath = '${dir.path}/aether';
      final p = cfg.vpn
          ? await _startTunSupervisor(dir, state, env)
          : await Process.start(
              corePath,
              const [],
              workingDirectory: state.path,
              environment: env,
              includeParentEnvironment: false,
            );
      if (gen != _generation) {
        p.kill(ProcessSignal.sigterm);
        await p.exitCode;
        return;
      }
      _process = p;
      var exited = false;
      final exitCode = p.exitCode.then((c) {
        exited = true;
        return c;
      });

      var vpnReady = false;
      void onLine(String line) {
        if (line.trim() == 'RAHVPN_TUN_READY') {
          vpnReady = true;
          return;
        }
        if (psiphon && line.contains('psiphon is ready')) {
          _psiphonReady = true;
          if (cfg.vpn) {
            try {
              _psiphonReadyFile?.writeAsStringSync('ready\n');
            } on Object {
              _recordLog(
                'warning: could not signal Psiphon readiness to TUN supervisor',
              );
            }
          }
        }
        _recordLog(line);
      }

      for (final stream in [p.stdout, p.stderr]) {
        stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(onLine, onError: (Object _) {});
      }

      // WireGuard/MASQUE: the SOCKS5 port opens only after real data crossed the tunnel.
      // Psiphon: the port opens at launch, so wait for the core's "psiphon is ready" line.
      final deadline = DateTime.now().add(_readyTimeout);
      var ready = false;
      while (gen == _generation && DateTime.now().isBefore(deadline)) {
        if (exited) {
          final code = await exitCode;
          throw StateError(
            cfg.vpn
                ? 'Linux TUN supervisor exited with code $code'
                : 'core exited with code $code',
          );
        }
        if (cfg.vpn) {
          if (vpnReady) {
            ready = true;
            break;
          }
        } else if ((!psiphon || _psiphonReady) && await _socksOpen()) {
          ready = true;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      if (gen != _generation) return;
      if (!ready) {
        throw StateError(
          cfg.vpn
              ? 'timed out waiting for the system TUN to become ready'
              : 'timed out waiting for the SOCKS5 port',
        );
      }
      _emit(AetherState.connected);

      final code = await exitCode;
      if (gen == _generation) {
        throw StateError(
          cfg.vpn
              ? 'Linux TUN supervisor exited with code $code'
              : 'core exited with code $code',
        );
      }
    } catch (e) {
      if (gen != _generation) return;
      final msg = e is StateError ? e.message : '$e';
      _recordLog('error: $msg');
      _generation++;
      await _kill();
      _emit(AetherState.error, msg);
    }
  }

  Future<Process> _startTunSupervisor(
    Directory coreDir,
    Directory state,
    Map<String, String> environment,
  ) async {
    final executable = File('${coreDir.path}/hev-socks5-tunnel');
    final supervisor = _tunSupervisor(coreDir)!;
    final helper = _routeHelper(coreDir);
    if (helper == null) throw StateError('Linux TUN route helper is missing.');
    final stopRequest = File('${state.path}/rahvpn-stop-request');
    if (stopRequest.existsSync()) stopRequest.deleteSync();
    _tunStopRequest = stopRequest;
    if (environment['AETHER_PSIPHON'] == 'only') {
      final readyFile = File('${state.path}/rahvpn-psiphon-ready');
      if (readyFile.existsSync()) readyFile.deleteSync();
      _psiphonReadyFile = readyFile;
    } else {
      _psiphonReadyFile = null;
    }
    final config = File('${state.path}/hev-socks5-tunnel.yml');
    // Map DNS for every Linux TUN mode. Without it, DNS can still depend on
    // the ISP resolver (which may poison or block domains such as x.com).
    const tunMapDns = '''
mapdns:
  address: 198.18.0.2
  port: 53
  network: 100.64.0.0
  netmask: 255.192.0.0
  cache-size: 10000
''';
    config.writeAsStringSync('''
tunnel:
  name: $_tunName
  mtu: 8500
  ipv4: 198.18.0.1
  ipv6: 'fc00::1'
  icmp: 'reply'
socks5:
  address: $_socksHost
  port: $_socksPort
  udp: 'udp'
  mark: $_socketMark
${tunMapDns}misc:
  log-level: warn
''');
    final user = (await Process.run('id', ['-un'])).stdout.toString().trim();
    final uid = (await Process.run('id', ['-u'])).stdout.toString().trim();
    final gid = (await Process.run('id', ['-g'])).stdout.toString().trim();
    if (user.isEmpty || uid.isEmpty || gid.isEmpty) {
      throw StateError('Could not determine the current Linux user and group.');
    }

    final args = <String>[
      supervisor.absolute.path,
      '--uid',
      uid,
      '--gid',
      gid,
      '--user',
      user,
      '--core',
      File('${coreDir.path}/aether').absolute.path,
      '--tun2socks',
      executable.absolute.path,
      '--tun-config',
      config.absolute.path,
      '--routes',
      helper.absolute.path,
      '--state-dir',
      state.absolute.path,
    ];
    for (final entry in environment.entries) {
      args.addAll(['--env', '${entry.key}=${entry.value}']);
    }
    return Process.start('pkexec', args, workingDirectory: state.path);
  }

  static File? _routeHelper(Directory coreDir) {
    final candidates = <String>[
      '${Directory.current.path}/tools/linux/linux_tun_routes.sh',
      '${coreDir.path}/rahvpn-tun-routes',
      '${File(Platform.resolvedExecutable).parent.path}/aether/rahvpn-tun-routes',
    ];
    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) return file;
    }
    return null;
  }

  static File? _tunSupervisor(Directory coreDir) {
    final candidates = <String>[
      '${Directory.current.path}/tools/linux/linux_tun_supervisor.sh',
      '${coreDir.path}/rahvpn-tun-supervisor',
      '${File(Platform.resolvedExecutable).parent.path}/aether/rahvpn-tun-supervisor',
    ];
    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) return file;
    }
    return null;
  }

  Future<String?> _resolveEnrollAddress(String ipPreference) async {
    final families = ipPreference == '6'
        ? [InternetAddressType.IPv6, InternetAddressType.IPv4]
        : [InternetAddressType.IPv4, InternetAddressType.IPv6];
    for (final family in families) {
      try {
        final addresses = await InternetAddress.lookup(
          'api.cloudflareclient.com',
          type: family,
        ).timeout(const Duration(seconds: 5));
        if (addresses.isNotEmpty) {
          final address = addresses.first.address;
          return family == InternetAddressType.IPv6 ? '[$address]' : address;
        }
      } on Object {
        // Try the other address family before reporting a DNS error.
      }
    }
    // This is a bootstrap optimization for marked sockets, not a prerequisite
    // for starting Aether (for example, an existing identity may need no API
    // enrollment). Let Aether try its own connection/fallback paths if the
    // system resolver cannot answer here.
    _recordLog(
      'warning: could not resolve api.cloudflareclient.com before startup; continuing without a pinned enrollment address',
    );
    return null;
  }

  /// Same override as on Android: prefer public resolvers so poisoned ISP DNS answers
  /// do not send Psiphon to bogon addresses.
  File _writePsiphonOverride(Directory state) {
    final f = File('${state.path}/psiphon-override.json');
    f.writeAsStringSync(
      '{"DNSResolverAlternateServers":["1.1.1.1","8.8.8.8","9.9.9.9"],'
      '"DNSResolverPreferredAlternateServers":["1.1.1.1","8.8.8.8","9.9.9.9"],'
      '"DNSResolverPreferAlternateServerProbability":1.0}\n',
    );
    return f;
  }

  Future<bool> _socksOpen() async {
    try {
      final s = await Socket.connect(
        _socksHost,
        _socksPort,
        timeout: const Duration(milliseconds: 300),
      );
      s.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
