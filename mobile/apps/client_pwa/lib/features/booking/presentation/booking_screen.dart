import 'package:client_pwa/l10n/generated/app_localizations.dart';
import 'package:fadespace_ui/fadespace_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Flujo de reserva Zero-Login: servicio → barbero → franja → datos.
class BookingScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? _service;
  String? _barber;
  String? _slot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookingTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.bookingSubtitle,
                style: theme.textTheme.bodySmall,
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
              child: StatusPill(
                label: 'Reserva en menos de 15 segundos',
                icon: Icons.bolt,
              ),
            ),
            const SizedBox(height: 20),
            _StepSection(
              index: 1,
              title: l10n.stepService,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final service in <String>[
                    l10n.serviceHaircut,
                    l10n.serviceBeard,
                    l10n.serviceCombo,
                  ])
                    ChoiceChip(
                      label: Text(service),
                      selected: _service == service,
                      onSelected: (_) => setState(() => _service = service),
                    ),
                ],
              ),
            ),
            _StepSection(
              index: 2,
              title: l10n.stepBarber,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final barber in <String>[
                    l10n.barberAndres,
                    l10n.barberCamilo,
                  ])
                    ChoiceChip(
                      label: Text(barber),
                      selected: _barber == barber,
                      onSelected: (_) => setState(() => _barber = barber),
                    ),
                ],
              ),
            ),
            _StepSection(
              index: 3,
              title: l10n.stepSlot,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final slot in <String>[
                    l10n.slotMorning,
                    l10n.slotMidday,
                    l10n.slotAfternoon,
                  ])
                    ChoiceChip(
                      label: Text(slot),
                      selected: _slot == slot,
                      onSelected: (_) => setState(() => _slot = slot),
                    ),
                ],
              ),
            ),
            _StepSection(
              index: 4,
              title: l10n.stepData,
              child: Text(l10n.privacyNotice, style: theme.textTheme.bodySmall),
            ),
            const SizedBox(height: 8),
            PrimaryActionButton(
              label: l10n.confirmBooking,
              icon: Icons.event_available,
              onPressed: () => context.go('/confirmation'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/appointment'),
              child: Text(l10n.myAppointmentTitle),
            ),
          ],
        ),
      ),
    );
  }
}

final class _StepSection extends StatelessWidget {
  const new({required this.index, required this.title, required this.child});

  final int index;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(radius: 16, child: Text('$index')),
              const SizedBox(width: 10),
              Text(title, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
