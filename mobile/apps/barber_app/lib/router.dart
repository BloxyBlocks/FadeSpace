import 'package:barber_app/features/agenda/presentation/agenda_screen.dart';
import 'package:barber_app/features/chair_mode/presentation/chair_mode_screen.dart';
import 'package:barber_app/features/earnings/presentation/earnings_screen.dart';
import 'package:barber_app/features/settings/presentation/settings_screen.dart';
import 'package:barber_app/shell/home_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Rutas de la app del barbero (ADR-007).
final routerProvider = Provider<GoRouter>((_) {
  return GoRouter(
    initialLocation: '/agenda',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/agenda',
                name: 'agenda',
                builder: (context, state) => const AgendaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/chair',
                name: 'chair',
                builder: (context, state) => const ChairModeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/earnings',
                name: 'earnings',
                builder: (context, state) => const EarningsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
