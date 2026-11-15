import 'package:barber_app/l10n/generated/app_localizations.dart';
import 'package:fadespace_ui/fadespace_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Agenda diaria en vivo del barbero.
///
/// En E-01 es una cáscara navegable con datos de ejemplo; en F2 se conecta a
/// `/api/v1/barber/agenda` y al canal privado de Reverb.
class AgendaScreen extends StatelessWidget {
  const new({super.key});

  static const _appointments = <({String time, String client, String service})>[
    (time: '09:00', client: 'Andrés', service: 'Corte clásico'),
    (time: '09:45', client: 'Camilo', service: 'Corte + barba'),
    (time: '10:30', client: 'Sebastián', service: 'Perfilado de barba'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.agendaTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.agendaSubtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(label: 'En línea', icon: Icons.wifi),
            ),
            const SizedBox(height: 16),
            for (final appointment in _appointments)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(child: Text(appointment.time)),
                    title: Text(appointment.client),
                    subtitle: Text(appointment.service),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            PrimaryActionButton(
              label: l10n.startService,
              icon: Icons.chair,
              onPressed: () => context.go('/chair'),
            ),
          ],
        ),
      ),
    );
  }
}
