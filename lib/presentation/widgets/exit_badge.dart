import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rah_app/core/theme/rah_colors.dart';
import 'package:rah_app/domain/entities/exit_info.dart';
import 'package:rah_app/presentation/utils/exit_info_display.dart';
import 'package:rah_app/presentation/widgets/country_flag_icon.dart';
import 'package:rah_app/l10n/generated/app_localizations.dart';

class ExitBadge extends StatelessWidget {
  const ExitBadge({
    super.key,
    required this.info,
    required this.caption,
    this.warnIran = false,
  });

  final ExitInfo info;
  final String caption;
  final bool warnIran;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final iran = warnIran && info.country == 'IR';
    final title =
        countryDisplayName(
          info.country,
          english: Localizations.localeOf(context).languageCode == 'en',
        ) ??
        info.country ??
        l.unknown;
    return Semantics(
      label: '$caption: $title ${info.ip ?? ''}',
      child: Material(
        color: RahColors.panel,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: iran ? RahColors.coral : RahColors.line),
        ),
        child: InkWell(
          onTap: info.ip == null
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: info.ip!));
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l.ipCopied)));
                  }
                },
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 18, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (info.country != null && info.country!.length == 2) ...[
                  CountryFlagIcon(country: info.country, width: 30),
                  const SizedBox(width: 12),
                ],
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: iran ? RahColors.coral : RahColors.foam,
                      ),
                    ),
                    if (info.ip != null)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          info.ip!,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: RahColors.mist,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    Text(
                      caption,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: RahColors.mist.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
