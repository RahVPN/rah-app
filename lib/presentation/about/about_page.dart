import 'package:flutter/material.dart';
import 'package:rah_app/core/constants/app_info.dart';
import 'package:rah_app/core/theme/app_spacing.dart';
import 'package:rah_app/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static final _releasesUrl = Uri.parse(
    'https://github.com/RahVPN/rah-app/releases/latest',
  );
  static final _sourceUrl = Uri.parse('https://github.com/RahVPN/rah-app');
  static final _telegramUrl = Uri.parse('https://t.me/rahvp');

  Future<void> _open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.about)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/icon/rahvpn.png', width: 120, height: 120),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              AppInfo.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(l.version),
                  subtitle: const Text(AppInfo.version),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l.contact, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.send_outlined),
                  title: Text(l.telegram),
                  subtitle: const Text('t.me/rahvp'),
                  onTap: () => _open(_telegramUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => _open(_releasesUrl),
            icon: const Icon(Icons.download_rounded),
            label: Text(l.downloadApk),
          ),
          TextButton.icon(
            onPressed: () => _open(_sourceUrl),
            icon: const Icon(Icons.code_rounded),
            label: Text(l.sourceCode),
          ),
        ],
      ),
    );
  }
}
