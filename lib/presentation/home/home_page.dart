import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:rah_app/app/rah_app.dart' show appLightTheme, appLocale;
import 'package:rah_app/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:rah_app/core/theme/app_text_styles.dart';
import 'package:rah_app/core/theme/rah_colors.dart';
import 'package:rah_app/domain/entities/aether_config.dart';
import 'package:rah_app/domain/entities/aether_state.dart';
import 'package:rah_app/domain/entities/exit_info.dart';
import 'package:rah_app/domain/services/aether_exit_log_parser.dart';
import 'package:rah_app/domain/usecases/aether_use_cases.dart';
import 'package:rah_app/domain/usecases/exit_info_use_cases.dart';
import 'package:rah_app/domain/usecases/settings_use_cases.dart';
import 'package:rah_app/presentation/constants/home_constants.dart';
import 'package:rah_app/presentation/about/about_page.dart';
import 'package:rah_app/presentation/utils/exit_info_display.dart';
import 'package:rah_app/presentation/widgets/connection_orb.dart';
import 'package:rah_app/presentation/widgets/exit_badge.dart';
import 'package:rah_app/presentation/widgets/country_flag_icon.dart';
import 'package:rah_app/presentation/widgets/protocol_selector.dart';

const _linuxTrayChannel = MethodChannel('com.rahvpn/tray');

String _fa(String s) =>
    s.replaceAllMapped(RegExp(r'\d'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]);

String _clock(Duration d, {required bool persian}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final value =
      '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  return persian ? _fa(value) : value;
}






class HomePage extends StatefulWidget {
  const HomePage({
    required this.connection,
    required this.settings,
    required this.exitInfo,
    super.key,
  });

  final AetherUseCases connection;
  final SettingsUseCases settings;
  final ExitInfoUseCases exitInfo;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _logs = <String>[];
  final _logRev = ValueNotifier<int>(0);

  AetherConfig _config = const AetherConfig();
  bool _settingsLoaded = false;
  AetherState _state = AetherState.idle;
  String? _message;
  ExitInfo? _exit;
  ExitInfo? _real;
  bool _realLoading = false;

  DateTime? _connectedAt;
  Timer? _tick;
  DateTime? _reconnectAfter;
  Timer? _reconnectTimer;

  StreamSubscription<AetherEvent>? _stateSub;
  StreamSubscription<String>? _logSub;

  @override
  void initState() {
    super.initState();
    if (Platform.isLinux) {
      _linuxTrayChannel.setMethodCallHandler(_handleTrayCall);
    }
    _restoreConfig();
    _realLoading = true;
    widget.exitInfo.fetch().then(_onReal);
    _stateSub = widget.connection.states.listen(
      _onState,
      onError: (Object _) {},
    );
    _logSub = widget.connection.logs.listen((line) {
      _logs.add(line);
      if (_logs.length > 300) _logs.removeRange(0, _logs.length - 300);
      _logRev.value++;
      final info = parseAetherExitLog(line);
      if (info != null && mounted) setState(() => _exit = info);
    }, onError: (Object _) {});
    widget.connection
        .currentState()
        .then((s) {
          if (mounted) {
            setState(() => _state = s);
            unawaited(_syncLinuxTrayState());
          }
        })
        .catchError((Object e) {
          if (!mounted) return;
          setState(() {
            _state = AetherState.error;
            _message = e is MissingPluginException ? _l.nativeMissing : '$e';
          });
        });
  }

  Future<void> _restoreConfig() async {
    try {
      _config = await widget.settings.load() ?? _config;
    } catch (_) {
      // Ignore unavailable or invalid saved settings and use app defaults.
    }
    if (mounted) setState(() => _settingsLoaded = true);
  }

  void _updateConfig(AetherConfig config) {
    setState(() => _config = config);
    unawaited(_saveConfig(config));
  }

  Future<void> _saveConfig(AetherConfig config) async {
    try {
      await widget.settings.save(config);
    } catch (_) {
      // Settings remain usable if the platform preference store is unavailable.
    }
  }

  @override
  void dispose() {
    if (Platform.isLinux) {
      _linuxTrayChannel.setMethodCallHandler(null);
    }
    _tick?.cancel();
    _reconnectTimer?.cancel();
    _stateSub?.cancel();
    _logSub?.cancel();
    _logRev.dispose();
    super.dispose();
  }

  void _onState(AetherEvent e) {
    if (!mounted) return;
    setState(() {
      _state = e.state;
      _message = e.message;
      if (e.state == AetherState.idle ||
          e.state == AetherState.error ||
          e.state == AetherState.stopping) {
        _exit = null;
      }
      if (e.state == AetherState.connected) {
        _connectedAt ??= DateTime.now();
        _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() {});
        });
      } else {
        _connectedAt = null;
        _tick?.cancel();
        _tick = null;
      }
    });
    unawaited(_syncLinuxTrayState());
    if (e.state == AetherState.idle || e.state == AetherState.error) {
      _loadRealIp();
    }
    if (e.state == AetherState.connected && _config.protocol == 'psiphon') {
      _loadTunnelExit();
    }
  }

  /// Psiphon prints no exit line, so read the exit through its local HTTP proxy.
  Future<void> _loadTunnelExit() async {
    for (var i = 0; i < 4; i++) {
      if (!mounted || _state != AetherState.connected || _exit != null) return;
      final info = await widget.exitInfo.fetch(
        proxy: HomeConstants.psiphonHttpProxy,
      );
      if (!mounted || _state != AetherState.connected) return;
      if (info != null) {
        setState(() => _exit = info);
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Widget _psiphonRegionChips() {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(_l.anyCountry),
          selected: _config.psiphonRegion.isEmpty,
          showCheckmark: false,
          onSelected: _locked
              ? null
              : (_) => _updateConfig(_config.copyWith(psiphonRegion: '')),
        ),
        for (final region in HomeConstants.psiphonRegions)
          ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountryFlagIcon(country: region, width: 20),
                const SizedBox(width: 6),
                Text(countryDisplayName(region, english: english) ?? region),
              ],
            ),
            selected: _config.psiphonRegion == region,
            showCheckmark: false,
            onSelected: _locked
                ? null
                : (_) => _updateConfig(_config.copyWith(psiphonRegion: region)),
          ),
      ],
    );
  }

  List<Widget> _psiphonSettings() {
    final hint = AppTextStyles.hintBodySmall(Theme.of(context));
    return [
      _label(_l.connectionShape),
      _chips(
        items: {
          'auto': _l.shapeAuto,
          'cdn': _l.shapeCdn,
          'direct': _l.shapeDirect,
        },
        value: _config.psiphonShape,
        onSelected: (v) => _updateConfig(_config.copyWith(psiphonShape: v)),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(_l.cdnHint, style: hint),
      ),
      const SizedBox(height: 16),
      _label(_l.exitCountry),
      _psiphonRegionChips(),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(_l.countryRetryHint, style: hint),
      ),
    ];
  }

  void _onReal(ExitInfo? r) {
    if (!mounted) return;
    setState(() {
      _real = r ?? _real;
      _realLoading = false;
    });
  }

  Future<void> _loadRealIp() async {
    if (_realLoading) return;
    setState(() => _realLoading = true);
    _onReal(await widget.exitInfo.fetch());
  }

  Widget _ipCard() {
    final hint = AppTextStyles.mutedBodySmall(Theme.of(context));
    if (_state == AetherState.connected) {
      final x = _exit;
      return x == null
          ? Text(_l.tunnelIpDetecting, style: hint)
          : ExitBadge(info: x, caption: _l.tunnelExitIp, warnIran: true);
    }
    final r = _real;
    if (r != null) {
      return ExitBadge(info: r, caption: _l.currentIpNoTunnel);
    }
    if (_realLoading) return Text(_l.ipDetecting, style: hint);
    return TextButton(onPressed: _loadRealIp, child: Text(_l.ipNotDetected));
  }

  bool get _running =>
      _state == AetherState.starting || _state == AetherState.connected;

  /// Settings are frozen while a session exists.
  bool get _locked =>
      !_settingsLoaded || _running || _state == AetherState.stopping;

  bool get _reconnectLocked =>
      _reconnectAfter != null && DateTime.now().isBefore(_reconnectAfter!);

  int get _reconnectSeconds => _reconnectLocked
      ? _reconnectAfter!.difference(DateTime.now()).inSeconds + 1
      : 0;

  Future<void> _toggle({bool fromTray = false}) async {
    if (!fromTray) HapticFeedback.mediumImpact();
    try {
      if (_running) {
        _reconnectTimer?.cancel();
        setState(
          () =>
              _reconnectAfter = DateTime.now().add(const Duration(seconds: 5)),
        );
        _reconnectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || !_reconnectLocked) {
            timer.cancel();
            if (mounted) setState(() => _reconnectAfter = null);
          } else {
            setState(() {});
          }
        });
        await widget.connection.disconnect();
      } else {
        if (_reconnectLocked) return;
        _logs.add(
          '--- VPN connection attempt ${DateTime.now().toIso8601String()} '
          '(mode: ${_config.vpn ? 'system TUN' : 'proxy-only'}, '
          'protocol: ${_config.protocol}) ---',
        );
        _logRev.value++;
        setState(() => _exit = null);
        await widget.connection.connect(_config);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_l.runFailed('$e'))));
    }
  }

  Future<void> _syncLinuxTrayState() async {
    if (!Platform.isLinux) return;
    try {
      await _linuxTrayChannel.invokeMethod<void>(
        'setConnectionState',
        _state.name,
      );
    } on PlatformException {
      // The native tray is optional while the Linux engine is starting up.
    } on MissingPluginException {
      // Ignore a missing tray channel on older Linux bundles.
    }
  }

  Future<Object?> _handleTrayCall(MethodCall call) async {
    switch (call.method) {
      case 'toggleConnection':
        await _toggle(fromTray: true);
        return null;
      case 'quitApplication':
        _reconnectTimer?.cancel();
        if (_state == AetherState.starting ||
            _state == AetherState.connected) {
          await widget.connection.disconnect();
        } else if (_state == AetherState.stopping) {
          await widget.connection.states.firstWhere(
            (event) =>
                event.state == AetherState.idle ||
                event.state == AetherState.error,
          );
        }
        return null;
      default:
        throw MissingPluginException(
          'Unknown RahVPN tray call: ${call.method}',
        );
    }
  }

  void _setProtocol(String p) {
    _updateConfig(
      _config.copyWith(
        protocol: p,
        noize: p == 'masque' ? 'firewall' : 'balanced',
        // gool's outer transport is MASQUE too; prefer TCP for restrictive networks.
        http2: p == 'gool' ? true : (p == 'masque' ? _config.http2 : false),
      ),
    );
  }

  String get _title => switch (_state) {
    AetherState.idle => _l.disconnected,
    AetherState.starting => _l.findingRoute,
    AetherState.connected => _l.connected,
    AetherState.stopping => _l.disconnecting,
    AetherState.error => _l.connectionFailed,
  };

  AppLocalizations get _l => AppLocalizations.of(context)!;

  Color get _titleColor => switch (_state) {
    AetherState.connected => RahColors.jade,
    AetherState.error => RahColors.coral,
    _ => RahColors.foam,
  };

  Widget _detail(BuildContext context) {
    final mist = AppTextStyles.mutedBodyMedium(Theme.of(context));
    switch (_state) {
      case AetherState.idle:
        return Text(
          _reconnectLocked
              ? _l.connectWait('$_reconnectSeconds')
              : _l.tapToConnect,
          style: mist,
        );
      case AetherState.starting:
        return Text(_l.checkingRoute, style: mist);
      case AetherState.stopping:
        return Text('', style: mist);
      case AetherState.connected:
        final at = _connectedAt;
        return Text(
          at == null
              ? _l.tunnelActive
              : _clock(
                  DateTime.now().difference(at),
                  persian: Localizations.localeOf(context).languageCode == 'fa',
                ),
          style: at == null
              ? mist
              : AppTextStyles.connectedTimer(Theme.of(context)),
        );
      case AetherState.error:
        return Column(
          children: [
            if (_message != null)
              Text(
                _message!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: mist.copyWith(color: RahColors.coral),
              ),
            TextButton(onPressed: _showLogs, child: Text(_l.viewLogs)),
          ],
        );
    }
  }

  void _showLogs() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: RahColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => ValueListenableBuilder<int>(
          valueListenable: _logRev,
          builder: (ctx, _, __) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
                child: Row(
                  children: [
                    Text(_l.logs, style: Theme.of(ctx).textTheme.titleMedium),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _logs.isEmpty
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: _logs.join('\n')),
                              );
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(_l.logsCopied)),
                                );
                              }
                            },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(_l.copy),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: _logs.isEmpty
                    ? ListView(
                        controller: scroll,
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text(
                            _l.noLogs,
                            style: AppTextStyles.mutedBodySmall(Theme.of(ctx)),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: scroll,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _logs.length,
                        itemBuilder: (_, i) {
                          final line = _logs[_logs.length - 1 - i];
                          final color =
                              line.contains('[-]') ||
                                  line.toLowerCase().startsWith('error')
                              ? RahColors.coral
                              : line.contains('[+]')
                              ? RahColors.jade
                              : RahColors.foam.withValues(alpha: 0.8);
                          return Directionality(
                            textDirection: TextDirection.ltr,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                line,
                                style: AppTextStyles.logLine(color),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(text, style: AppTextStyles.sectionLabel(Theme.of(context))),
  );

  Widget _chips({
    required Map<String, String> items,
    required String value,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in items.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: e.key == value,
            showCheckmark: false,
            onSelected: _locked ? null : (_) => onSelected(e.key),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noize = _config.protocol == 'masque'
        ? HomeConstants.masqueNoize
        : HomeConstants.wireGuardNoize;
    final ipLabel = _config.ip == 'dual'
        ? _l.dualIpVersion
        : HomeConstants.ipVersions[_config.ip] ?? _config.ip;

    final overview = <Widget>[
      Center(
        child: ConnectionOrb(
          state: _state,
          disabledSeconds: _reconnectSeconds,
          onTap:
              !_settingsLoaded ||
                  _state == AetherState.stopping ||
                  _reconnectLocked
              ? null
              : _toggle,
        ),
      ),
      const SizedBox(height: 4),
      Center(
        child: Text(
          _title,
          style: theme.textTheme.headlineSmall!.copyWith(
            color: _titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey(_state), child: _detail(context)),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(
                '${_state == AetherState.connected}-${_exit?.ip}-${_real?.ip}-$_realLoading',
              ),
              child: _ipCard(),
            ),
          ),
        ),
      ),
    ];

    final controls = <Widget>[
      ProtocolSelector(
        value: _config.protocol,
        enabled: !_locked,
        onChanged: _setProtocol,
      ),
      const SizedBox(height: 24),
      Material(
        color: RahColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: RahColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: const EdgeInsetsDirectional.fromSTEB(
                20,
                4,
                12,
                4,
              ),
              title: Text(_l.vpnMode),
              subtitle: Text(_config.vpn ? _l.allAppsTunnel : _l.proxyOnly),
              value: _config.vpn,
              onChanged: _locked
                  ? null
                  : (v) => _updateConfig(_config.copyWith(vpn: v)),
            ),
            const Divider(),
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 4),
                childrenPadding: const EdgeInsetsDirectional.fromSTEB(
                  20,
                  0,
                  20,
                  20,
                ),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(_l.connectionSettings),
                subtitle: Text(
                  _config.protocol == 'psiphon'
                      ? _l.psiphonSummary(
                          _config.psiphonShape == 'auto'
                              ? _l.shapeAuto
                              : _config.psiphonShape == 'direct'
                              ? _l.shapeDirect
                              : _l.shapeCdn,
                          _config.psiphonRegion.isEmpty
                              ? _l.anyCountry
                              : (countryDisplayName(
                                      _config.psiphonRegion,
                                      english:
                                          Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'en',
                                    ) ??
                                    _config.psiphonRegion),
                        )
                      : _l.scanSummary(_config.scan, _config.noize, ipLabel),
                ),
                children: _config.protocol == 'psiphon'
                    ? _psiphonSettings()
                    : [
                        _label(_l.scanMode),
                        _chips(
                          items: {for (final s in HomeConstants.scans) s: s},
                          value: _config.scan,
                          onSelected: (v) =>
                              _updateConfig(_config.copyWith(scan: v)),
                        ),
                        const SizedBox(height: 16),
                        _label(_l.obfuscation),
                        _chips(
                          items: {for (final n in noize) n: n},
                          value: _config.noize,
                          onSelected: (v) =>
                              _updateConfig(_config.copyWith(noize: v)),
                        ),
                        const SizedBox(height: 16),
                        _label(_l.ipVersion),
                        _chips(
                          items: {
                            '4': 'IPv4',
                            '6': 'IPv6',
                            'dual': _l.dualIpVersion,
                          },
                          value: _config.ip,
                          onSelected: (v) =>
                              _updateConfig(_config.copyWith(ip: v)),
                        ),
                        if (_config.protocol == 'masque' ||
                            _config.protocol == 'gool') ...[
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_l.http2Title),
                            subtitle: Text(_l.http2Hint),
                            value: _config.http2,
                            onChanged: _locked
                                ? null
                                : (v) =>
                                      _updateConfig(_config.copyWith(http2: v)),
                          ),
                        ],
                      ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            tooltip: _l.logs,
            onPressed: _showLogs,
            icon: const Icon(Icons.receipt_long_rounded),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: _l.about,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const AboutPage())),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          textDirection: TextDirection.ltr,
          children: [
            Text(
              'Rah VPN',
              style: theme.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: appLightTheme.value ? _l.switchToDark : _l.switchToLight,
              onPressed: () => appLightTheme.value = !appLightTheme.value,
              icon: Icon(
                appLightTheme.value
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
            ),
            IconButton(
              tooltip: _l.languageTooltip,
              onPressed: () {
                final locale = Locale(
                  appLocale.value.languageCode == 'fa' ? 'en' : 'fa',
                );
                appLocale.value = locale;
              },
              icon: CountryFlagIcon(
                country: Localizations.localeOf(context).languageCode == 'en'
                    ? 'IR'
                    : 'US',
                width: 26,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 1120 : 520),
                child: wide
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  const SizedBox(height: 16),
                                  ...overview,
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 6,
                              child: Column(children: controls),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        children: [
                          ...overview,
                          const SizedBox(height: 32),
                          ...controls,
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
