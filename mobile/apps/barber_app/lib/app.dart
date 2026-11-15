import 'package:barber_app/l10n/generated/app_localizations.dart';
import 'package:barber_app/router.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:fadespace_ui/fadespace_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Raíz de la app del barbero.
///
/// Toda la app vive dentro de [ProviderScope] (Riverpod) y usa `go_router`
/// para la navegación (ADR-007).
class BarberApp extends ConsumerWidget {
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
