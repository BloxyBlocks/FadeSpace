# Plan de arquitectura e implementación — FadeSpace

**Versión:** 1.0  
**Estado:** Borrador · pendiente de aprobación (G2)  
**Autor:** Diego Alejandro Zamora Gallego  
**Depende de:** `01-spec.md`

---

## 1. Arquitectura general

Backend monolítico modular (Laravel) que expone una API REST y un servidor WebSocket (Reverb), con tres clientes: dashboard web, app del barbero y PWA del cliente.

```
┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐  ┌──────────────┐
│ Dashboard Admin    │  │ App Barbero        │  │ PWA Cliente        │  │ Pantalla TV  │
│ Livewire + Alpine  │  │ Flutter (iOS/And.) │  │ Flutter Web        │  │ Blade+Alpine │
└─────────┬──────────┘  └─────────┬──────────┘  └─────────┬──────────┘  └──────┬───────┘
          │ HTTPS / WSS           │ REST + WS             │ REST + WS          │ WS (token)
          ▼                       ▼                       ▼                    ▼
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  Nginx (TLS)  →  PHP-FPM  (Laravel API /api/v1 · Livewire · rutas públicas)           │
│                  Laravel Reverb (WebSockets)  ·  Horizon (workers de colas)           │
│                  Scheduler (rescate de huecos, recordatorios, expiraciones)           │
└──────────────┬─────────────────────────────────────────────┬─────────────────────────┘
               │                                             │
        ┌──────▼──────┐                               ┌──────▼──────┐
        │   MySQL 8   │                               │   Redis 7   │
        │ (datos,     │                               │ holds, OTP, │
        │  locks)     │                               │ caché, colas│
        └─────────────┘                               │ pub/sub WS  │
                                                      └─────────────┘
Servicios externos: proveedor SMS/WhatsApp (OtpChannel) · WhatsApp Business API · pasarela de pagos
```

### Flujo de una mutación crítica

```
Request → ResolveTenant → Auth/Policy → FormRequest
        → UseCase (Application)
            └─ DB::transaction
                 ├─ lockForUpdate (si aplica)
                 ├─ reglas de Dominio (puras)
                 ├─ persistir (repositorios)
                 └─ auditar
            └─ afterCommit → Domain Event → Broadcast (Reverb) / Job
        → JsonResource
```

### Decisiones clave

| ID | Decisión | Motivo |
|---|---|---|
| D-01 | `appointment_services` reemplaza `appointments.service_id` | Permitir varios servicios con *snapshot* de precio y duración |
| D-02 | Multi-tenant por `tenant_id` en esquema compartido + `TenantScope` global | Simplicidad operativa y costo; el aislamiento se verifica con pruebas (C-03) |
| D-03 | *Mutex* por silla con `SELECT … FOR UPDATE` sobre la fila del barbero + revalidación de traslapes | MySQL no tiene restricciones de exclusión por rango |
| D-04 | *Hold* en Redis con *script* Lua atómico | Evitar condiciones de carrera entre verificar y crear |
| D-05 | Broadcasts solo `afterCommit` | Evitar eventos "fantasma" ante *rollback* |
| D-06 | Clean Architecture pragmática: Eloquent vive en `Infrastructure`, el dominio usa entidades/VO puros solo donde hay reglas (disponibilidad, comisiones, estados, cola) | Equilibrio entre pureza y productividad |
| D-07 | Transacciones solo de inserción, con reversos | Integridad financiera (C-06) |
| D-08 | Pantalla de TV autenticada con *display token* revocable | Un TV no puede iniciar sesión |
| D-09 | Monorepo (`backend/`, `mobile/`, `docs/`) | Un solo lugar para spec, plan y trazabilidad |

Las decisiones que dependen de un *spike* o de terceros se registran como ADR (ver §10).

---

## 2. Estructura del repositorio

```
fadespace/
├─ backend/                      # Laravel
├─ mobile/                       # Monorepo Flutter (melos)
├─ docs/
│  ├─ 00-constitucion.md
│  ├─ 01-spec.md
│  ├─ 02-plan.md
│  ├─ 03-tasks.md
│  ├─ 04-traceability.md
│  ├─ adr/                       # ADR-001 … ADR-0xx
│  └─ openapi/                   # Contrato /api/v1
├─ infra/                        # Docker, Nginx, Supervisor, scripts de despliegue
└─ .github/workflows/            # CI/CD (o equivalente)
```

---

## 3. Estructura del backend (Laravel)

```
backend/
├─ app/
│  ├─ Domain/                                   # PHP puro, sin Illuminate
│  │  ├─ Shared/
│  │  │  ├─ Money.php  Clock.php  TenantId.php  DomainException.php
│  │  │  └─ Phone.php (E.164)  TimeRange.php
│  │  ├─ Tenancy/        TenantSettings.php  Plan.php  PlanGate.php
│  │  ├─ Identity/       Role.php  CommissionRule.php
│  │  ├─ Scheduling/
│  │  │  ├─ AppointmentStatus.php  AppointmentStateMachine.php
│  │  │  ├─ AvailabilityCalculator.php  SlotGrid.php  FirstAvailableSelector.php
│  │  │  ├─ SlotHold.php  Contracts/ (AppointmentRepository, SlotHoldStore, TimeBlockRepository)
│  │  │  └─ Events/ (AppointmentConfirmed, AppointmentCancelled, …)
│  │  ├─ Queue/          WalkInPlacer.php  WaitTimeEstimator.php
│  │  ├─ Billing/
│  │  │  ├─ CommissionEngine.php
│  │  │  ├─ Strategies/ PercentageStrategy.php FixedServiceStrategy.php ChairRentalStrategy.php
│  │  │  └─ CashClosingCalculator.php
│  │  └─ Rescue/         GapDetector.php  CustomerCycleAnalyzer.php  OfferPolicy.php
│  │
│  ├─ Application/                              # Casos de uso (orquestan, transaccionan)
│  │  ├─ Tenancy/        ProvisionTenant  UpdateTenantSettings
│  │  ├─ Identity/       AuthenticateStaff  ManageBarber  RequestOtp  VerifyOtp
│  │  ├─ Catalog/        ManageService  ManageSchedule  BlockTime
│  │  ├─ Booking/        GetAvailability  CreateSlotHold  ConfirmAppointment
│  │  │                  CancelAppointment  RescheduleAppointment  MarkNoShow
│  │  ├─ Chair/          StartService  CompleteAndCharge  QuickBlock  GetBarberDailyMetrics
│  │  ├─ Queue/          AddWalkIn  RecalculateQueue  GetQueueSnapshot
│  │  ├─ Billing/        RegisterTransaction  ReverseTransaction  CloseCashRegister  GetCashSummary
│  │  ├─ Rescue/         DetectGaps  SendGapOffer  AcceptGapOffer
│  │  ├─ Notifications/  SendNotification  ScheduleReminders
│  │  ├─ Subscriptions/  StartSubscription  HandlePaymentWebhook  EnforcePlanLimits
│  │  └─ Privacy/        ExportCustomerData  AnonymizeCustomer
│  │
│  ├─ Infrastructure/
│  │  ├─ Persistence/
│  │  │  ├─ Eloquent/    Models (Tenant, User, Customer, Service, Appointment, …)
│  │  │  ├─ Concerns/    BelongsToTenant  TenantScope
│  │  │  └─ Repositories/ EloquentAppointmentRepository …
│  │  ├─ Cache/          RedisSlotHoldStore (Lua)  RedisOtpStore  TenantCache  CatalogCache
│  │  ├─ Realtime/       Broadcasters (eventos → canales)  ChannelAuthorizers
│  │  ├─ Messaging/      Contracts/OtpChannel  SmsOtpChannel  WhatsAppChannel  LogChannel
│  │  ├─ Payments/       PaymentGateway (interfaz)  <Proveedor>Gateway
│  │  ├─ Tenancy/        TenantContext  ResolveTenant (middleware)  TenantAwareJob
│  │  └─ Observability/  RequestContext (request_id, tenant_id)  Metrics
│  │
│  ├─ Http/
│  │  ├─ Controllers/Api/V1/   (Public, Staff, Barber, Admin, Display)
│  │  ├─ Requests/  Resources/  Middleware/  (Idempotency, Throttle, EnsureTenantActive)
│  │  └─ Policies/
│  ├─ Livewire/                 # Dashboard y modo TV
│  │  ├─ Admin/ (Agenda, Barbers, Services, Schedules, Cash, Reports, Settings, Display)
│  │  └─ Tv/ QueueBoard
│  ├─ Console/Commands/         tenant:create, gaps:scan, reminders:send, appointments:expire-pending
│  ├─ Jobs/  Listeners/  Providers/
├─ routes/ (api.php, web.php, channels.php, console.php)
├─ config/ (tenancy.php, booking.php, billing.php, reverb.php)
├─ database/ (migrations, factories, seeders)
├─ resources/ (views, lang/es)
└─ tests/
   ├─ Unit/Domain/            # AvailabilityCalculator, CommissionEngine, StateMachine, WalkInPlacer, Money
   ├─ Architecture/           # Regla de dependencia entre capas
   ├─ Feature/                # API: booking, chair, billing, tenancy, auth
   ├─ Integration/            # MySQL + Redis reales: locking, holds, OTP, aislamiento
   ├─ Concurrency/            # 50 reservas simultáneas
   ├─ Realtime/               # Entrega de eventos, latencia
   └─ Load/                   # k6/Artillery
```

---

## 4. Estructura de la app Flutter

Monorepo gestionado con `melos`:

```
mobile/
├─ melos.yaml
├─ apps/
│  ├─ barber_app/                 # Android / iOS
│  │  └─ lib/
│  │     ├─ main.dart  app.dart  router.dart
│  │     └─ features/
│  │        ├─ auth/        (data · domain · presentation)
│  │        ├─ agenda/      agenda diaria en vivo
│  │        ├─ chair_mode/  Cliente en Silla · Finalizar y Cobrar · Bloqueo rápido
│  │        ├─ walk_in/     agregar walk-in
│  │        ├─ earnings/    métricas y liquidación del barbero
│  │        └─ settings/
│  └─ client_pwa/                 # Flutter Web
│     └─ lib/
│        └─ features/
│           ├─ booking/     servicio → barbero → franja → datos → OTP → confirmación
│           ├─ my_appointment/  ver, cancelar, reprogramar
│           ├─ queue_status/    turno y espera estimada
│           └─ history/
├─ packages/
│  ├─ fadespace_core/          # Modelos, Money, errores, constantes
│  ├─ fadespace_api/           # Cliente HTTP (dio): tenant, token, Idempotency-Key, reintentos
│  ├─ fadespace_realtime/      # Cliente WebSocket (protocolo Pusher/Reverb), reconexión, snapshot
│  └─ fadespace_ui/            # Tema Material 3, tokens, componentes (botón de acción grande, chips de franja)
└─ test/ · integration_test/
```

- Estado: **Riverpod**; navegación: **go_router**; HTTP: **dio**; modelos: **freezed**.
- Cliente WebSocket: librería compatible con el protocolo Pusher (decisión final en ADR-004 tras el *spike* T-008).
- Cada `feature` sigue `presentation → domain ← data`.

---

## 5. Modelo de datos

El modelo completo (columnas, tipos, índices) está en `01-spec.md` §8. Resumen de relaciones:

```
tenants 1───* users 1───* appointments *───1 customers
   │              │              │ 1
   │              │              ├──* appointment_services *──1 services
   │              │              └──* transactions *──1 users(barber)
   │              ├──* barber_schedules
   │              └──* time_blocks
   ├──* services
   ├──* customers
   ├──* display_devices                       (F2)
   ├──* cash_closings 1──* cash_closing_barbers  (F3)
   ├──* gap_offers · notification_logs        (F3)
   ├──* subscriptions · tenant_addons         (F3)
   └──* audit_logs
```

### Índices obligatorios

| Tabla | Índice | Uso |
|---|---|---|
| `appointments` | `(tenant_id, barber_id, scheduled_date, status)` | Agenda y disponibilidad |
| `appointments` | `(tenant_id, customer_id, scheduled_start)` | Historial |
| `appointments` | `(tenant_id, status, scheduled_start)` | Recordatorios, expiración, rescate |
| `customers` | `UNIQUE(tenant_id, phone)` | Búsqueda y *upsert* |
| `users` | `UNIQUE(tenant_id, phone)` | Login |
| `transactions` | `(tenant_id, barber_id, created_at)`, `(tenant_id, settled_at)` | Caja y liquidación |
| `time_blocks` | `(tenant_id, barber_id, starts_at)` | Disponibilidad |

---

## 6. Servicios de caché y Redis

### Claves

| Clave | TTL | Contenido |
|---|---|---|
| `t:{tid}:hold:{holdId}` | 180 s | Hold: `barberId`, `start`, `end`, `sessionId` |
| `t:{tid}:holds:{barberId}:{date}` | Dinámico | Índice (ZSET por `start`) de *holds* vivos del día |
| `t:{tid}:hold:session:{sessionId}` | 180 s | Hold activo de la sesión (RN-11) |
| `t:{tid}:otp:{phone}` | 300 s | *Hash* del OTP e intentos restantes |
| `t:{tid}:otp:rate:{phone}` / `rl:otp:ip:{ip}` | 3600 s | Contadores de envío |
| `t:{tid}:catalog` | Invalidación explícita | Servicios y precios activos |
| `t:{tid}:settings` | Invalidación explícita | Configuración, horarios, reglas de comisión |
| `t:{tid}:barber:{id}:schedule` | Invalidación explícita | Horario semanal del barbero |
| `t:{tid}:queue:{date}` | Corto / invalidación | *Snapshot* de la fila para TV y PWA |
| `idem:{tid}:{key}` | 24 h | Respuesta de operaciones idempotentes |
| `tenant:domain:{domain}` | 10 min | Resolución de dominio → tenant |

> La disponibilidad **no** se cachea (depende de *holds* y citas en vivo); se calcula con consultas indexadas.

### *Script* Lua del *hold* (resumen)

1. Leer holds vivos del barbero y día; descartar vencidos.
2. Si algún rango se traslapa con el solicitado → devolver conflicto.
3. Liberar el hold previo de la sesión, crear el nuevo con `EX 180` e indexarlo.
4. Todo en una única operación atómica.

---

## 7. API interna (`/api/v1`)

### Pública (cliente Zero-Login) — tenant por dominio

```
GET    /public/tenant                         → marca, servicios, barberos, métodos
GET    /public/availability?services[]&barber_id|first_available&date
POST   /public/holds                          → { hold_id, expires_at }
DELETE /public/holds/{holdId}
POST   /public/otp/request                    { name, phone, consent }
POST   /public/otp/verify                     { phone, code } → customer_token
POST   /public/appointments                   { hold_id }  (Idempotency-Key)
GET    /public/appointments/me                (token de cliente)
POST   /public/appointments/{id}/cancel
POST   /public/appointments/{id}/reschedule   { hold_id }
GET    /public/queue                          → estado de fila (token de cliente)
GET    /public/history
```

### Personal (admin / barbero) — Sanctum

```
POST   /auth/login   POST /auth/logout   GET /auth/me   DELETE /auth/devices/{id}

# Barbero
GET    /barber/agenda?date=
POST   /barber/appointments/{id}/start        (Cliente en Silla)
POST   /barber/appointments/{id}/complete     { payment_method } (Idempotency-Key)
POST   /barber/appointments/{id}/no-show
POST   /barber/blocks/quick                   { minutes }
POST   /barber/walk-ins                       { name, phone?, services[] }
GET    /barber/metrics/today
GET    /barber/settlement?from&to

# Administración
CRUD   /admin/barbers   /admin/services   /admin/schedules   /admin/blocks
GET|PUT /admin/settings
GET    /admin/agenda?date=
POST   /admin/appointments   PATCH /admin/appointments/{id}   POST /admin/appointments/{id}/cancel
POST   /admin/walk-ins
GET    /admin/cash/summary?date=
POST   /admin/transactions/{id}/reverse
POST   /admin/cash/close                      { date, cash_counted }
GET    /admin/reports/{type}?from&to          (+ export CSV)
CRUD   /admin/display-devices
GET    /admin/audit
GET|POST /admin/subscription
```

### Pantalla de TV — *display token*

```
GET    /display/queue                         → snapshot inicial
```

### Tiempo real (Reverb)

Autorización en `routes/channels.php`: `tenant.{tenantId}.admin`, `tenant.{tenantId}.barber.{barberId}`, `tenant.{tenantId}.queue`, `tenant.{tenantId}.availability.{barberId}`. Eventos definidos en `01-spec.md` §8.7.

### Convenciones

- Errores: `{ "code": "SLOT_TAKEN", "message": "…", "details": {} }`.
- Códigos de dominio: `SLOT_TAKEN`, `HOLD_EXPIRED`, `OTP_INVALID`, `OTP_RATE_LIMITED`, `INVALID_TRANSITION`, `PLAN_LIMIT_REACHED`, `TENANT_SUSPENDED`, `ALREADY_SETTLED`, `DUPLICATE_REQUEST`.
- Cabeceras: `Idempotency-Key`, `X-Client-Version` (versión mínima soportada), `X-Request-Id`.

---

## 8. Seguridad (implementación)

- **Sanctum:** tokens de personal con *ability* `staff`; tokens de cliente con *ability* `customer:booking` y expiración de 30 días; `Customer` usa `HasApiTokens`.
- **Tenant en el token:** el token queda ligado al tenant; si el dominio resuelto no coincide, `403`.
- **Throttling:** `RateLimiter` por IP, teléfono y tenant en endpoints públicos; límites de OTP según RN-22/RN-23.
- **TV:** `display token` aleatorio de 40+ caracteres, guardado como *hash*; revocable en `display_devices`.
- **Webhooks** (WhatsApp, pasarela): verificación de firma y *replay protection*.
- **Auditoría:** *listener* que escribe `audit_logs` en la misma transacción de la operación auditada.
- **Privacidad:** *job* de anonimización de clientes; los logs enmascaran teléfonos.
- **Secretos:** variables de entorno; rotación documentada en *runbook*.

---

## 9. Calidad, pruebas e infraestructura

### Pruebas

| Nivel | Herramienta | Alcance clave |
|---|---|---|
| Unitarias de dominio | Pest | `AvailabilityCalculator`, `CommissionEngine` (con pruebas de propiedades: `total = barber + shop`), `AppointmentStateMachine`, `WalkInPlacer`, `Money` |
| Arquitectura | Pest Arch / Deptrac | `Domain` no importa `Illuminate`; `Application` no importa `Http` |
| Integración | Pest + MySQL/Redis reales | Locking, *holds* (Lua), OTP, idempotencia, aislamiento |
| Concurrencia | Pest + procesos paralelos | 50 solicitudes a una franja → 1 éxito (ESC-04) |
| Tiempo real | Pest + cliente WS | Entrega y latencia p95 < 200 ms |
| Carga | k6 / Artillery | 1.000 conexiones WS; disponibilidad y confirmación |
| Flutter | `flutter test`, *golden*, `integration_test` | Modo Silla, reserva, resincronización |
| E2E | Playwright (PWA) | Reserva completa ≤ 15 s (cliente recurrente) |
| Manual | Checklist | 360 px, accesibilidad, 3G real, dispositivos reales |

Cobertura objetivo: ≥ 80 % en `app/Domain` y `app/Application`; ≥ 70 % en `domain`/`data` de Flutter.

### Entornos e infraestructura

- **Local:** Docker Compose (PHP-FPM, Nginx, MySQL 8, Redis 7, Mailpit, Reverb).
- **Staging y producción:** contenedores o VPS administrado con Nginx (TLS), PHP-FPM, MySQL 8 gestionado o replicado, Redis 7, Supervisor para Reverb y Horizon, y *scheduler* (`schedule:work`/cron).
- **CI/CD:** pipeline con Pint, Larastan, Pest, `composer audit`, `flutter analyze`, `flutter test`; despliegue a *staging* automático desde `develop` y a producción manual desde `main` con aprobación.
- **Observabilidad:** logs JSON (`tenant_id`, `request_id`), métricas de latencia WS, tasa de errores, profundidad de colas y alertas; monitor sintético de latencia de eventos.
- **Respaldos:** MySQL diario (retención 30 días) + *binlog*; prueba de restauración trimestral.
- **Migraciones:** retrocompatibles en dos pasos (expandir → contraer).

---

## 10. ADR planificados

| ADR | Decisión | Fase |
|---|---|---|
| ADR-001 | Estrategia multi-tenant (esquema compartido + `TenantScope`) | F0 |
| ADR-002 | Autenticación (Sanctum, tokens de cliente y TV) | F0 |
| ADR-003 | Locking de reservas (mutex por silla + revalidación) | F0 |
| ADR-004 | Cliente WebSocket en Flutter para Reverb (mobile y web) | F0 (*spike* T-008) |
| ADR-005 | Flutter Web vs. página liviana para la PWA de reserva | F0 (*spike* T-009) |
| ADR-006 | Proveedor de SMS/WhatsApp para OTP en F1 | F0 |
| ADR-007 | Estado y navegación en Flutter (Riverpod, go_router) | F0 |
| ADR-008 | Pasarela de pagos para suscripciones | Antes de F3 |
| ADR-009 | Estrategia de despliegue y hosting | F1 |

---

## 11. Fases de implementación

| Fase | Contenido | Criterio de salida (release gate) | Duración orientativa |
|---|---|---|---|
| **F0 — Cimientos** | Repositorio, Docker, CI, arquitectura base, pruebas de arquitectura, *spikes* de WebSocket y de peso de Flutter Web, ADR iniciales | G1 y G2 aprobadas; *spikes* resueltos; CI verde | 1–2 semanas |
| **F1 — MVP Core** (Meses 1–2) | Multi-tenant con aislamiento, auth del personal, catálogo, horarios, dashboard admin, reserva Zero-Login (PWA), *hold* + *locking*, auditoría base | Un tenant de prueba reserva de punta a punta sin overbooking; ESC-01…07, 18, 22, 23, 24 verificados; suite de aislamiento en verde | ~8 semanas |
| **F2 — Tiempo real y movilidad** (Meses 3–4) | Reverb, app del barbero (Modo Silla, cobro, bloqueo rápido), motor de comisiones y transacciones, *walk-ins*, fila virtual y Pantalla de TV | Silla → cobro → TV en vivo con p95 < 200 ms; ESC-08…10, 12…16, 21, 25, 26 verificados; app en distribución interna | ~8 semanas |
| **F3 — Automatización y monetización** (Meses 5–6) | Rescate de huecos, WhatsApp Business, cierre de caja y liquidación avanzada, reportes, suscripciones y *onboarding* autoservicio | ESC-11, 17, 19, 20 verificados; cobro de suscripciones operando; G4 convergencia | ~8 semanas |

### Alcance por fase

**F1 — MVP Core:** RF-01…17, RF-38, RF-39. Entregables: `tenants/users/customers/services/appointments/appointment_services/barber_schedules/time_blocks/audit_logs`, `ResolveTenant`, `TenantScope`, disponibilidad, *hold*, OTP (canal SMS), confirmación con *lock*, cancelación/reprogramación, dashboard con agenda, PWA de reserva.

**F2 — Tiempo real y movilidad:** RF-18…31. Entregables: Reverb y canales, app del barbero, `transactions`, `CommissionEngine`, `display_devices`, `WalkInPlacer`, `WaitTimeEstimator`, Pantalla de TV, PWA de fila, caja diaria básica.

**F3 — Automatización y monetización:** RF-32…37, RF-40, RF-41. Entregables: `cash_closings`, liquidación por barbero (incluido alquiler), `gap_offers`, WhatsApp, `subscriptions`, `tenant_addons`, *feature gating*, *onboarding*, historial y privacidad de clientes.

---

## 12. Riesgos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Fuga de datos entre tenants por una consulta sin *scope* | Media | Crítico | `TenantScope` global, prueba de fuga en CI, revisión de `withoutGlobalScopes`, pruebas de canales |
| Overbooking por condición de carrera | Media | Alto | *Hold* atómico (Lua) + mutex MySQL + prueba de concurrencia (T-141) |
| Peso de Flutter Web inviable en 3G | Alta | Alto | *Spike* T-009; presupuesto de carga; alternativa liviana (ADR-005) |
| Latencia WS > 200 ms bajo carga | Media | Alto | *Spike* T-008, métrica `emitted_at`, escalado Reverb con Redis, pruebas de carga |
| Cliente Flutter para Reverb inmaduro en web/móvil | Media | Medio | *Spike* y ADR-004; capa de abstracción `fadespace_realtime` |
| OTP/WhatsApp: costos, bloqueos o aprobación de plantillas | Alta | Medio | Interfaz `OtpChannel`, *fallback* SMS, iniciar aprobación de plantillas en F2 |
| Errores de dinero (redondeo, duplicados) | Media | Alto | `Money` con `bcmath`, pruebas de propiedades, `Idempotency-Key`, transacciones inmutables |
| Barbero con mala conectividad en sala | Media | Medio | Estados explícitos, reintentos idempotentes, resincronización con *snapshot* |
| Redis como punto único de falla | Media | Medio | Degradación segura (RNF-15), persistencia/réplica de Redis, sondeo como respaldo |
| Cumplimiento de protección de datos (Ley 1581) | Media | Alto | Consentimiento registrado, minimización, anonimización, política de privacidad |
| Crecimiento de alcance (multi-sucursal, inventario, propinas) | Alta | Medio | Backlog separado; cambios solo vía control de cambios |
| Ambigüedad en planes y precios | Media | Medio | OQ-01 resuelta antes de F3; *feature gating* configurable |
| Un solo desarrollador (autor) como punto único de conocimiento | Alta | Medio | Documentación SEDD, ADR, pruebas y trazabilidad al día |

---

## 13. Trazabilidad

La matriz completa vive en `04-traceability.md`. Cada requisito debe tener módulo, tarea y prueba asociados antes de cerrar G4.
