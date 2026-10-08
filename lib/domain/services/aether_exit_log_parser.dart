
import 'package:rah_app/domain/entities/exit_info.dart';

ExitInfo? parseAetherExitLog(String line) {
  final match = RegExp(r'\[\+\] .+? exit: (.+)$').firstMatch(line);
  if (match == null) return null;

  String? ip;
  String? country;
  String? colo;
  for (final part in match.group(1)!.split(', ')) {
    final value = part.trim();
    final countryMatch = RegExp(
      r'^([A-Z]{2})(?: via (\S+))?$',
    ).firstMatch(value);
    if (countryMatch != null) {
      country = countryMatch.group(1);
      colo = countryMatch.group(2);
    } else if (RegExp(r'^[0-9a-fA-F:.]+$').hasMatch(value) &&
        RegExp(r'[.:]').hasMatch(value)) {
      ip = value;
    }
  }
  if (ip == null && country == null) return null;
  return ExitInfo(ip: ip, country: country, colo: colo);
}
