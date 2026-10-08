import 'package:flutter/material.dart';
import 'package:rah_app/core/theme/rah_colors.dart';
import 'package:rah_app/presentation/constants/home_constants.dart';
import 'package:rah_app/l10n/generated/app_localizations.dart';

/// Displays the active connection protocol and lets the user change it.
class ProtocolSelector extends StatelessWidget {
  const ProtocolSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final name = HomeConstants.protocolNames[value] ?? value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l.connectionProtocol, style: theme.textTheme.titleMedium),
            const Spacer(),
            DecoratedBox(
              decoration: BoxDecoration(
                color: RahColors.jade.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: RahColors.jade.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: RahColors.jade),
                    const SizedBox(width: 6),
                    Text(
                      l.activeProtocol(name),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: RahColors.jade,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in HomeConstants.protocolNames.entries)
                  _ProtocolOption(
                    width: width,
                    name: entry.value,
                    selected: entry.key == value,
                    enabled: enabled,
                    onTap: () => onChanged(entry.key),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          switch (value) {
            'masque' => l.protocolHintMasque,
            'wg' => l.protocolHintWg,
            'gool' => l.protocolHintGool,
            'psiphon' => l.protocolHintPsiphon,
            _ => '',
          },
          style: theme.textTheme.bodySmall?.copyWith(color: RahColors.mist),
        ),
      ],
    );
  }
}

class _ProtocolOption extends StatelessWidget {
  const _ProtocolOption({
    required this.width,
    required this.name,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final double width;
  final String name;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? RahColors.jade : RahColors.line;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: name,
      child: Material(
        color: selected ? RahColors.jade.withValues(alpha: 0.13) : RahColors.panel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color, width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: selected ? RahColors.jade : RahColors.foam,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 20,
                  color: selected ? RahColors.jade : RahColors.mist,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
