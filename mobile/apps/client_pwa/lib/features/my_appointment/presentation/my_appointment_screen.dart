import 'package:client_pwa/l10n/generated/app_localizations.dart';
import 'package:fadespace_ui/fadespace_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Detalle de la cita del cliente y estado de la fila.
class MyAppointmentScreen extends StatelessWidget {
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
        title: Text(l10n.myAppointmentTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Corte clásico',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Andrés · 10:00 a. m.'),
                    const SizedBox(height: 12),
                    const StatusPill(
                      label: 'Confirmada',
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timelapse),
                title: Text(l10n.estimatedWait),
                trailing: Text('12 min', style: theme.textTheme.titleMedium),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_calendar),
              label: Text(l10n.rescheduleAppointment),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.close),
              label: Text(l10n.cancelAppointment),
            ),
          ],
        ),
      ),
    );
  }
}
