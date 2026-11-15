import 'package:barber_app/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Ajustes y datos de contexto del barbero.
class SettingsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.storefront),
              title: Text(l10n.settingsTenant),
              subtitle: const Text('Barbería El Roble'),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.settingsBarber),
              subtitle: const Text('Andrés Rojas'),
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(l10n.settingsLocale),
              subtitle: const Text('Español (Colombia)'),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: Text(l10n.settingsTimezone),
              subtitle: const Text('America/Bogota'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsVersion),
              subtitle: const Text('0.1.0 (F0)'),
            ),
          ],
        ),
      ),
    );
  }
}
