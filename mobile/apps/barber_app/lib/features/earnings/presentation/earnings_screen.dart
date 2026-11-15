import 'package:barber_app/l10n/generated/app_localizations.dart';
import 'package:fadespace_core/fadespace_core.dart';
import 'package:material_ui/material_ui.dart';

/// Resumen de ganancias y comisión del barbero.
class EarningsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final today = Money.parse('128500.00');
    final week = Money.parse('742300.00');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.earningsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _EarningsCard(
              label: l10n.earningsToday,
              amount: today,
              highlight: true,
            ),
            const SizedBox(height: 12),
            _EarningsCard(label: l10n.earningsWeek, amount: week),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.percent),
                title: Text(l10n.commissionLabel),
                trailing: Text('40 %', style: theme.textTheme.titleMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _EarningsCard extends StatelessWidget {
  const new({
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  final String label;
  final Money amount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: highlight ? scheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _formatCop(amount),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: highlight ? scheme.onPrimaryContainer : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCop(Money money) {
    final whole = money.minorUnits ~/ 100;
    final digits = whole.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }

    return '\$ $buffer';
  }
}
