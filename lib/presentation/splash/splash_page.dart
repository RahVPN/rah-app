import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rah_app/core/theme/rah_colors.dart';
import 'package:rah_app/l10n/generated/app_localizations.dart';
import 'package:rah_app/presentation/home/home_page.dart';


class SplashPage extends StatefulWidget {
  const SplashPage({
    required this.homePage,
    required this.onLocaleChanged,
    required this.locale,
    super.key,
  });

  final HomePage homePage;
  final ValueChanged<Locale> onLocaleChanged;
  final Locale locale;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => widget.homePage),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icon/rahvpn.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Rah VPN',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: RahColors.foam,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.appSlogan,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: RahColors.mist,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => widget.onLocaleChanged(
                Locale(widget.locale.languageCode == 'fa' ? 'en' : 'fa'),
              ),
              child: Text(l.languageName),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 100,
              height: 2,
              child: LinearProgressIndicator(
                
                color: RahColors.jade,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
