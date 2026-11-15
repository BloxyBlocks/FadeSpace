import 'package:barber_app/l10n/generated/app_localizations.dart';
import 'package:fadespace_ui/fadespace_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Modo Silla: el flujo de un toque para atender y cobrar.
class ChairModeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chairModeTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const StatusPill(label: 'En silla', icon: Icons.chair),
              const SizedBox(height: 24),
              Text(
                'Andrés',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(l10n.serviceHaircut, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(l10n.chairInstruction, style: theme.textTheme.bodyMedium),
              const Spacer(),
              PrimaryActionButton(
                label: l10n.finishAndCharge,
                icon: Icons.point_of_sale,
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.commissionLabel)));
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.block),
                label: Text(l10n.quickBlock),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
