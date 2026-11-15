import 'package:client_pwa/l10n/generated/app_localizations.dart';
import 'package:client_pwa/router.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:fadespace_ui/fadespace_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// PWA Zero-Login para reservar una cita.
class ClientPwaApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: FadeSpaceTheme.light(),
      darkTheme: FadeSpaceTheme.dark(),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es', 'CO'),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
