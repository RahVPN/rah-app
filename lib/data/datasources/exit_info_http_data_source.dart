import 'dart:convert';
import 'dart:io';

import 'package:rah_app/domain/entities/exit_info.dart';


class ExitInfoHttpDataSource {
  Future<ExitInfo?> fetch({String? proxy}) async {
    for (final url in const [
      'https://www.cloudflare.com/cdn-cgi/trace',
      'https://1.1.1.1/cdn-cgi/trace',
    ]) {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      if (proxy != null) client.findProxy = (_) => 'PROXY $proxy';
      try {
        final request = await client
            .getUrl(Uri.parse(url))
            .timeout(const Duration(seconds: 6));
        final response = await request.close().timeout(
          const Duration(seconds: 6),
        );
        if (response.statusCode != 200) continue;

        final body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 6));
        final fields = <String, String>{
          for (final line in body.split('\n'))
            if (line.contains('='))
              line.substring(0, line.indexOf('=')): line
                  .substring(line.indexOf('=') + 1)
                  .trim(),
        };
        final ip = fields['ip'];
        if (ip == null || ip.isEmpty) continue;
        return ExitInfo(ip: ip, country: fields['loc'], colo: fields['colo']);
      } catch (_) {
        // Try the second trace endpoint.
      } finally {
        client.close(force: true);
      }
    }
    return null;
  }
}
