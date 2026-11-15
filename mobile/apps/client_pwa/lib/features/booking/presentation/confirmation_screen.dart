import 'package:client_pwa/l10n/generated/app_localizations.dart';
import 'package:fadespace_ui/fadespace_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Confirmación de la cita reservada.
class ConfirmationScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.backLabel,
        ),
        title: Text(l10n.bookingConfirmedTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(
                Icons.check_circle,
                size: 72,
                color: Color(0xFF0F5132),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.bookingConfirmedTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.bookingConfirmedBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              const StatusPill(
                label: '10:00 a. m. · Andrés',
                icon: Icons.schedule,
              ),
              const Spacer(),
              PrimaryActionButton(
                label: l10n.myAppointmentTitle,
                icon: Icons.event_note,
                onPressed: () => context.go('/appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
