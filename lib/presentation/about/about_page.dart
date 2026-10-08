import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/icon/rahvpn.png', width: 120, height: 120),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Rah VPN',
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
                  subtitle: const Text('0.2.3'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l.contact, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
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
