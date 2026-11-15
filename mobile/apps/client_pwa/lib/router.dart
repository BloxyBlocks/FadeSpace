import 'package:client_pwa/features/booking/presentation/booking_screen.dart';
import 'package:client_pwa/features/booking/presentation/confirmation_screen.dart';
import 'package:client_pwa/features/my_appointment/presentation/my_appointment_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Rutas de la PWA del cliente (ADR-007).
final routerProvider = Provider<GoRouter>((_) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'booking',
        builder: (context, state) => const BookingScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'confirmation',
            name: 'confirmation',
            builder: (context, state) => const ConfirmationScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/appointment',
        name: 'appointment',
        builder: (context, state) => const MyAppointmentScreen(),
      ),
    ],
  );
});
