# ADR-007 — Estado y navegación en Flutter: Riverpod 3 + `go_router`

- **Estado:** Aceptado
- **Fecha:** 2026-11-14
- **Requisitos:** C-10, RNF-07, RNF-08, RF-18, RF-19
- **Tareas:** T-012 (*scaffold*), T-220…T-225 (Modo Silla y agenda), T-228 (resincronización)

## Contexto

La app del barbero debe sostener cuatro flujos simultáneos mientras el barbero trabaja de pie y con una mano:

1. Agenda del día que se actualiza por WebSocket.
2. **Modo Silla** con acciones de 1 toque y cobro en ≤ 2 toques (RNF-07).
3. Ganancias/comisión y ajustes.
4. Conexión intermitente: hay que mostrar el estado (en línea, reconectando, sin conexión) y reintentar sin perder
   el contexto de la pantalla.

En F0 ya existen `apps/barber_app` y `apps/client_pwa` con la navegación implementada, así que este ADR documenta y
fija la decisión que el código ya materializa.

## Decisión

1. **Estado con Riverpod 3 (`flutter_riverpod`)**:
   - `ProviderScope` en la raíz; sin singletons globales mutables.
   - `Provider` para dependencias inyectables (router, clientes de API y realtime), `AsyncNotifier`/`Notifier`
     para estado de pantalla y `StreamProvider` para flujos de Reverb y conectividad.
   - La UI consume `AsyncValue` (`data`/`loading`/`error`) y nunca llama directamente a la API: pasa por un
     repositorio del paquete correspondiente (`fadespace_api`, `fadespace_realtime`).
   - Pruebas con `ProviderScope(overrides: […])`, sin mocks de framework.
2. **Navegación con `go_router` 18**:
   - `MaterialApp.router` + `routerConfig` provisto por Riverpod (`routerProvider`).
   - `StatefulShellRoute.indexedStack` para las cuatro pestañas del barbero (`/agenda`, `/chair`, `/earnings`,
     `/settings`), conservando el estado de cada rama al cambiar de pestaña.
   - La PWA usa rutas por *path* (`/`, `/confirmation`, `/appointment`) para que los enlaces de WhatsApp y los
     *deep links* funcionen; no se usan rutas hash.
   - `name:` en cada ruta para navegar por nombre (`context.goNamed`) y evitar *strings* dispersos.
3. **Reglas de capa** (constitución §5): `presentation` no contiene reglas de negocio; `domain` y `data` no
   importan widgets. Los `widgets` de `fadespace_ui` son puros y reciben callbacks.
4. **Errores y estados**: cada mutación expone `loading`, `success` y `failure`; los fallos de dominio
   (`SLOT_TAKEN`, `HOLD_EXPIRED`) se muestran con el mensaje de `AppLocalizations`, nunca con el `code` crudo.
5. **Localización**: `flutter gen-l10n` con ARB `es` (base) + `es_CO`, `Locale('es','CO')` fijado en F0; todos los
   textos de UI vienen de `AppLocalizations` (RNF-16).
6. **Sin `setState` para estado compartido**: solo para estado efímero de un widget (por ejemplo, la selección de
   un *chip* antes de confirmar).

## Alternativas descartadas

| Alternativa | Por qué no |
|---|---|
| BLoC (`flutter_bloc`) | Excelente, pero exige *events* y *states* explícitos por pantalla; con 4 flujos y un solo desarrollador es más ceremonia que beneficio. Riverpod cubre lo mismo con menos código y mejor testabilidad. |
| `provider` + `ChangeNotifier` | Mutabilidad y `BuildContext` implícito; difícil de testear sin *widget tests*. |
| GetX | Servicio locator global, navegación y estado acoplados; contradice la separación de capas y la testabilidad que exige C-15. |
| `Navigator` 1.0 + `onGenerateRoute` | Sin *deep links* declarativos ni restauración por rama; la PWA necesita URLs reales. |
| `auto_route` | Generación de código adicional sin ventaja clara frente a `go_router` 18 para este tamaño. |

## Consecuencias

**Positivas**

- El estado de cada pestaña sobrevive al cambio de pestaña (`indexedStack`), clave en Modo Silla.
- Inyección de dependencias explícita: los tests de widget y de unidad no necesitan red.
- `AsyncValue` obliga a diseñar los estados de carga y error, que es exactamente el requisito de conectividad
  (C-13/RNF-15).
- `go_router` da URLs reales para la PWA y *deep links* para notificaciones.

**Negativas y mitigaciones**

- Riverpod 3 cambió parte de la API (`Notifier` sin `StateNotifier`) → el *scaffold* ya usa la API nueva y
  `very_good_analysis` está en verde; se documenta la versión en `melos`/`pubspec`.
- `go_router` con `StatefulShellRoute` complica las redirecciones de autenticación → un solo `redirect` global
  basado en el estado de sesión, probado con *widget tests*.
- Riesgo de providers globales mal tipados → regla de revisión: todo provider declara su tipo explícito y su
  dependencia; `provider` sin dependencias solo para constantes de configuración.

## Verificación

- `apps/barber_app/test/widget_test.dart`: navegación entre Agenda, Modo Silla, Ganancias y Ajustes; textos en
  español desde ARB.
- `apps/client_pwa/test/widget_test.dart`: flujo de reserva, confirmación y "Mi cita" con rutas reales.
- `flutter analyze` limpio con `very_good_analysis` en los 6 paquetes (Melos), ejecutado en CI.
- F2: prueba de reconexión que verifica que el estado de la pantalla se conserva y se re-sincroniza el *snapshot*.

## Referencias

- `docs/02-plan.md` §5 (estructura móvil), §10 ADR-007.
- `docs/00-constitucion.md` §5 (Flutter), C-10, C-15.
- `mobile/pubspec.yaml`, `mobile/apps/*/lib/router.dart`.
