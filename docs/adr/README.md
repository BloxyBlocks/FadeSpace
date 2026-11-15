# Registro de decisiones de arquitectura (ADR)

**Proyecto:** FadeSpace
**Autor:** Diego Alejandro Zamora Gallego
**Convención:** `ADR-NNN-titulo-en-ingles.md`; contenido en español; un ADR por decisión.
**Regla (C-17):** toda dependencia nueva y toda decisión técnica estructural exige un ADR. Un ADR aceptado no se reescribe: se reemplaza por otro que lo supersede.

## Estados

| Estado | Significado |
|---|---|
| `Propuesto` | Escrito y argumentado; pendiente de ratificación humana en G1/G2. |
| `Aceptado` | Ratificado; se aplica en el código. |
| `Aceptado (sujeto a ratificación)` | La evidencia medida obliga a decidir ya para no bloquear F0; la ratificación formal ocurre en la puerta G2 (T-007). |
| `Reemplazado por ADR-NNN` | Vigente solo como historia. |

## Índice

| ADR | Decisión | Fase | Estado |
|---|---|---|---|
| [ADR-001](ADR-001-multi-tenant-strategy.md) | Multi-tenant por esquema compartido + `tenant_id` + `TenantScope` global *fail-closed* | F0 | Aceptado |
| [ADR-002](ADR-002-authentication.md) | Autenticación con Sanctum: tokens de personal, token de cliente con *ability* limitada y *display token* de TV | F0 | Aceptado |
| [ADR-003](ADR-003-booking-locking.md) | *Hold* atómico en Redis + mutex MySQL por barbero con revalidación de traslapes | F0 | Aceptado |
| [ADR-004](ADR-004-realtime-client.md) | Cliente WebSocket propio sobre `web_socket_channel` (protocolo Pusher) en `fadespace_realtime` | F0 (*spike* T-008) | Aceptado |
| [ADR-005](ADR-005-client-booking-frontend.md) | Página de reserva liviana server-rendered como entrada; Flutter Web no cubre el embudo público | F0 (*spike* T-009) | Aceptado (ratificado 2026-11-14) |
| [ADR-006](ADR-006-otp-provider.md) | OTP por SMS con Twilio en F1 detrás de `OtpChannel`; WhatsApp Cloud API en F3 | F0 | Propuesto (OQ-03) |
| [ADR-007](ADR-007-flutter-state-navigation.md) | Riverpod 3 + `go_router` 18 con `StatefulShellRoute` | F0 | Aceptado |
| [ADR-010](ADR-010-toolchain-baseline.md) | Línea base de toolchain: PHP 8.4, Laravel 13, Pest 5, Larastan 3, Flutter 3.50, Melos 8 | F0 | Aceptado |

## Evidencia de los *spikes*

| *Spike* | Evidencia | Resumen |
|---|---|---|
| T-008 (latencia Reverb) | [`spikes/t008/latency-40.json`](../../spikes/t008/latency-40.json), [`spikes/t008/emit-40.log`](../../spikes/t008/emit-40.log) | 40/40 eventos; p50 **17,808 ms**, p95 **18,820 ms**, máx. 31,773 ms (loopback, `127.0.0.1`) |
| T-009 (peso y TTI) | [`spikes/t009/size.json`](../../spikes/t009/size.json), [`spikes/t009/lighthouse-3g.json`](../../spikes/t009/lighthouse-3g.json) | Primera carga real **2,32 MB** (CanvasKit desde CDN) > presupuesto de 2 MB; FCP 4,67 s; sin elemento LCP medible |

## Pendientes conocidos

- **ADR-005 ratificado el 2026-11-14.** Falta reflejarlo en `02-plan.md` §5/§7 y re-planificar T-160…T-165, lo que
  ocurre al cerrar G2 (T-007) por control de cambios.
- **ADR-006** depende de OQ-03 (proveedor de OTP) y de validación de costos con negocio.
- ADR-008 (pasarela de pagos) y ADR-009 (despliegue y hosting) siguen fuera de F0 según `02-plan.md` §10.
