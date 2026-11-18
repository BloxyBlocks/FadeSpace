# Matriz de trazabilidad — FadeSpace

**Versión:** 1.3  
**Estado:** F0 cerrada en G2 (2026-11-17) · infraestructura validada en entorno real (T-100) · F1–F3 pendientes  
**Autor:** Diego Alejandro Zamora Gallego  
**Regla:** ningún requisito se cierra en G4 sin módulo, tarea y prueba asociados (C-02).

**Cómo leer esta matriz:**

- *Módulo* usa rutas relativas a `backend/app/` (Laravel) o `mobile/` (Flutter).
- *Prueba* indica el archivo o suite que verifica el requisito (`tests/…` en Laravel; `test/…` en Flutter).
- *Estado* se actualiza al completar la tarea: `Pendiente` → `En curso` → `Completado (Fx)`.

---

## 1. Constitución → mecanismo de cumplimiento

| Regla | Principio | Mecanismo de verificación | Tareas | Estado |
|---|---|---|---|---|
| C-01 | La especificación manda | Control de cambios (constitución §14), revisión en G1–G4 | T-007, T-346 | En curso |
| C-02 | Trazabilidad total | Este documento actualizado en cada tarea; revisión en G4 | T-004, T-346 | En curso |
| C-03 | Aislamiento multi-tenant | `TenantScope`, `TenantCache`, canales autorizados; suite de fuga en CI | T-102, T-103, T-104, T-105, T-110, T-202 | Pendiente |
| C-04 | Integridad transaccional e idempotencia | `DB::transaction`, `Idempotency-Key`, `afterCommit`; pruebas de integración | T-140, T-203, T-212, T-224 | Pendiente |
| C-05 | Cero overbooking | *Hold* (Lua) + `FOR UPDATE`; prueba de concurrencia | T-135, T-136, T-140, T-141 | Pendiente |
| C-06 | Dinero exacto e inmutable | `Money` (`bcmath`), tabla de solo inserción, reversos; pruebas de propiedades | T-131, T-210, T-211, T-212, T-213 | Pendiente |
| C-07 | Clean Architecture | Pruebas de arquitectura en CI | T-006 | Completado (F0) |
| C-08 | Estándares de código | Pint (PSR-12), Larastan nivel 8, `flutter analyze` en CI | T-005, T-011, T-012, T-100 | Cumple (CI remoto verde y protección de `main` aplicada) |
| C-09 | Tiempo real < 200 ms | Métrica `emitted_at`, monitor sintético y carga WS | T-008, T-203, T-206, T-207 | En curso (F0: p95 18,8 ms en local; carga real pendiente) |
| C-10 | Mobile-first y ergonomía | Tema de Modo Silla, *golden tests*, checklist 360 px | T-012, T-220, T-223, T-225, T-343 | Pendiente |
| C-11 | Zero-Login seguro | OTP con *hash*, límites de tasa, token de alcance limitado | T-137, T-138 | Pendiente |
| C-12 | Seguridad y privacidad | Autenticación, consentimiento, anonimización, revisión OWASP | T-108, T-139, T-312, T-341, T-342 | Pendiente |
| C-13 | Rendimiento y recursos | Índices, caché Redis, `preventLazyLoading`, presupuesto de la página de reserva | T-105, T-130, T-133, T-164 | Pendiente |
| C-14 | Observabilidad y auditoría | `RequestContext`, logs JSON, `audit_logs` | T-014, T-146, T-154 | Completado (F0, base; auditoría en F1) |
| C-15 | Calidad verificable | CI obligatorio; DoD por tarea; suites críticas (aislamiento, concurrencia, dinero) | T-011, T-100, T-110, T-141 | Cumple en F0 (checks obligatorios en `main`; suites críticas llegan con F1/F2) |
| C-16 | Puertas de aprobación | Revisión humana en G1-G4 y *release gates* | T-007, T-172, T-251, T-346 | En curso (G1/G2 aprobadas 2026-11-17; G3/G4 pendientes) |
| C-17 | Simplicidad sostenible | ADR por dependencia; backlog separado | T-013, T-345 | Completado (F0; ADR-001…007 y 010) |
| C-18 | Tiempo y zona horaria | `Clock`, UTC en almacenamiento, `scheduled_date` local | T-131, T-130 | Pendiente |

---

## 2. Requisitos funcionales

### Tenancy e identidad

| Req. | Módulo principal | Tarea | Prueba / verificación | Fase | Estado |
|---|---|---|---|---|---|
| RF-01 | `Application/Tenancy/ProvisionTenant`, `Console/Commands/tenant:create` | T-101, T-106, T-333 | `tests/Feature/Tenancy/ProvisionTenantTest` | F1 (autoservicio F3) | Pendiente |
| RF-02 | `Infrastructure/Tenancy/ResolveTenant`, `Infrastructure/Persistence/Concerns/TenantScope` | T-102, T-103, T-104 | `tests/Integration/Tenancy/TenantIsolationTest`, `tests/Feature/Tenancy/ResolveTenantTest` | F1 | Pendiente |
| RF-03 | `Application/Identity/AuthenticateStaff`, `Http/Controllers/Api/V1/Staff/AuthController`, `Http/Policies` | T-108, T-109 | `tests/Feature/Auth/StaffAuthTest` | F1 | Pendiente |
| RF-04 | `Application/Identity/ManageBarber`, `Livewire/Admin/Barbers` | T-111, T-151 | `tests/Feature/Admin/BarbersTest`, `tests/Feature/Tenancy/PlanGateTest` | F1 | Pendiente |
| RF-05 | `Application/Catalog/ManageService`, `Infrastructure/Cache/CatalogCache` | T-120, T-151 | `tests/Feature/Catalog/ServicesTest` | F1 | Pendiente |
| RF-06 | `Domain/Tenancy/TenantSettings`, `Livewire/Admin/Settings` | T-121, T-151 | `tests/Unit/Domain/Tenancy/TenantSettingsTest` | F1 | Pendiente |
| RF-07 | `Application/Catalog/ManageSchedule`, `Application/Catalog/BlockTime` | T-122 | `tests/Feature/Catalog/SchedulesTest` | F1 | Pendiente |

### Reserva Zero-Login

| Req. | Módulo principal | Tarea | Prueba / verificación | Fase | Estado |
|---|---|---|---|---|---|
| RF-08 | `Domain/Scheduling/AvailabilityCalculator`, `Application/Booking/GetAvailability`, `resources/views/booking/` | T-132, T-133, T-161 | `tests/Unit/Domain/Scheduling/AvailabilityCalculatorTest`, `tests/Feature/Booking/AvailabilityTest` | F1 | Pendiente |
| RF-09 | `Infrastructure/Cache/RedisSlotHoldStore`, `Application/Booking/CreateSlotHold` | T-135, T-136 | `tests/Integration/Booking/SlotHoldTest` | F1 | Pendiente |
| RF-10 | `Infrastructure/Cache/RedisOtpStore`, `Infrastructure/Messaging/OtpChannel`, `Application/Identity/RequestOtp`/`VerifyOtp`, vistas `booking` | T-137, T-138, T-162 | `tests/Feature/Booking/OtpTest` | F1 | Pendiente |
| RF-11 | `Application/Booking/ConfirmAppointment` | T-140, T-141 | `tests/Integration/Booking/ConfirmAppointmentTest`, `tests/Concurrency/ConcurrentBookingTest` | F1 | Pendiente |
| RF-12 | `Domain/Scheduling/FirstAvailableSelector` | T-134 | `tests/Unit/Domain/Scheduling/FirstAvailableSelectorTest` | F1 | Pendiente |
| RF-13 | `Application/Booking/CancelAppointment`/`RescheduleAppointment`, vistas `my_appointment` | T-143, T-163 | `tests/Feature/Booking/CustomerCancelTest` | F1 | Pendiente |
| RF-14 | `Application/Identity/CustomerResolver` | T-139 | `tests/Feature/Booking/CustomerResolverTest` | F1 | Pendiente |
| RF-15 | `Domain/Scheduling/AppointmentStateMachine` | T-130, T-142 | `tests/Unit/Domain/Scheduling/AppointmentStateMachineTest` | F1 | Pendiente |
| RF-16 | `Application/Booking/MarkNoShow`, `Application/Booking/CancelAppointment` (personal) | T-144, T-249 | `tests/Feature/Booking/StaffCancelNoShowTest` | F1 | Pendiente |
| RF-17 | `Livewire/Admin/Agenda` | T-152 | `tests/Feature/Admin/AgendaTest` | F1 | Pendiente |

### App del barbero / Modo Silla

| Req. | Módulo principal | Tarea | Prueba / verificación | Fase | Estado |
|---|---|---|---|---|---|
| RF-18 | `Http/.../Barber/AgendaController`, `mobile/apps/barber_app/.../agenda` | T-222 | `tests/Feature/Barber/AgendaTest`, `test/features/agenda/agenda_controller_test.dart` | F2 | Pendiente |
| RF-19 | `Application/Chair/StartService`, `barber_app/.../chair_mode` | T-223 | `tests/Feature/Chair/StartServiceTest`, *golden test* del botón | F2 | Pendiente |
| RF-20 | `Application/Chair/CompleteAndCharge`, `barber_app/.../chair_mode` | T-224, T-225 | `tests/Feature/Chair/CompleteAndChargeTest` | F2 | Pendiente |
| RF-21 | `Application/Chair/QuickBlock` | T-226 | `tests/Feature/Chair/QuickBlockTest` | F2 | Pendiente |
| RF-22 | `Application/Chair/GetBarberDailyMetrics`, `barber_app/.../earnings` | T-227, T-324 | `tests/Feature/Barber/MetricsTest` | F2 | Pendiente |

### Fila virtual y walk-ins

| Req. | Módulo principal | Tarea | Prueba / verificación | Fase | Estado |
|---|---|---|---|---|---|
| RF-23 | `Domain/Queue/WalkInPlacer`, `Application/Queue/AddWalkIn`, `barber_app/.../walk_in`, `Livewire/Admin/Agenda` | T-240, T-241, T-246, T-247 | `tests/Unit/Domain/Queue/WalkInPlacerTest`, `tests/Feature/Queue/AddWalkInTest` | F2 | Pendiente |
| RF-24 | `Domain/Queue/WaitTimeEstimator`, `Application/Queue/RecalculateQueue` | T-240, T-242 | `tests/Unit/Domain/Queue/WaitTimeEstimatorTest`, `tests/Feature/Queue/RecalculateQueueTest` | F2 | Pendiente |
| RF-25 | `Livewire/Tv/QueueBoard`, `display_devices` | T-243, T-244, T-245 | `tests/Feature/Display/DisplayTokenTest`, `tests/Realtime/TvBoardTest` | F2 | Pendiente |
| RF-26 | `resources/views/queue/` | T-248 | `tests/Feature/Queue/QueueStatusTest` | F2 | Pendiente |

### Tiempo real

| Req. | Módulo principal | Tarea | Prueba / verificación | Fase | Estado |
|---|---|---|---|---|---|
| RF-27 | `Infrastructure/Realtime/*`, `routes/channels.php`, `fadespace_realtime` | T-201, T-202, T-203, T-204, T-206, T-207 | `tests/Realtime/BroadcastDeliveryTest`, `tests/Realtime/ChannelAuthorizationTest`, `tests/Load/ws-latency.js` | F2 | Pendiente |
| RF-28 | Endpoints de *snapshot*, `fadespace_realtime` (reconexión) | T-205, T-208, T-228 | `tests/Feature/Realtime/SnapshotTest`, `test/realtime/reconnect_test.dart` | F2 | Pendiente |

### Finanzas

| Req. | Módulo principal | Tarea | Prueba / verificación | Fase | Estado |
|---|---|---|---|---|---|
| RF-29 | `Domain/Billing/CommissionEngine`, `Domain/Billing/Strategies/*` | T-211 | `tests/Unit/Domain/Billing/CommissionEngineTest` (incluye propiedades) | F2 | Pendiente |
| RF-30 | `Application/Billing/RegisterTransaction`/`ReverseTransaction`, tabla `transactions` | T-210, T-212, T-213 | `tests/Feature/Billing/TransactionTest`, `tests/Feature/Billing/ReversalTest` | F2 | Pendiente |
| RF-31 | `Application/Billing/GetCashSummary`, `Livewire/Admin/Cash` | T-214, T-215 | `tests/Feature/Billing/CashSummaryTest` | F2 | Pendiente |
| RF-32 | `Domain/Billing/CashClosingCalculator`, `Application/Billing/CloseCashRegister`, `barber_app/.../earnings` | T-320, T-321, T-322, T-323, T-324 | `tests/Unit/Domain/Billing/CashClosingCalculatorTest`, `tests/Feature/Billing/CloseCashRegisterTest` | F3 | Pendiente |
| RF-33 | `Application/Billing/*Report*`, `Livewire/Admin/Reports` | T-325 | `tests/Feature/Billing/ReportsTest` | F3 | Pendiente |

### Automatización y monetización

| Req. | Módulo principal | Tarea | Prueba / verificación | Fase | Estado |
|---|---|---|---|---|---|
| RF-34 | `Domain/Rescue/*`, `Application/Rescue/*`, `gap_offers` | T-301, T-302, T-303, T-304, T-305, T-306, T-307 | `tests/Unit/Domain/Rescue/*Test`, `tests/Feature/Rescue/GapOfferTest` | F3 | Pendiente |
| RF-35 | `Infrastructure/Messaging/WhatsAppChannel`, `Application/Notifications/*`, `notification_logs` | T-310, T-311, T-312, T-313, T-314, T-315 | `tests/Feature/Notifications/WhatsAppTest`, `tests/Feature/Notifications/RemindersTest` | F3 | Pendiente |
| RF-36 | `Application/Subscriptions/*`, `Infrastructure/Payments/*`, `subscriptions` | T-330, T-331, T-332, T-333 | `tests/Feature/Subscriptions/SubscriptionLifecycleTest` | F3 | Pendiente |
| RF-37 | `Domain/Tenancy/PlanGate`, `Application/Subscriptions/EnforcePlanLimits` | T-330, T-332, T-334, T-315 | `tests/Unit/Domain/Tenancy/PlanGateTest`, `tests/Feature/Tenancy/PlanLimitsTest` | F3 | Pendiente |

### Transversales

| Req. | Módulo principal | Tarea | Prueba / verificación | Fase | Estado |
|---|---|---|---|---|---|
| RF-38 | `audit_logs`, `Listeners/WriteAuditLog`, `Livewire/Admin/Audit` | T-146, T-154 | `tests/Feature/Audit/AuditTrailTest` | F1 | Pendiente |
| RF-39 | `Livewire/Admin/Agenda`, `Livewire/Admin/Dashboard` | T-150, T-152, T-153 | `tests/Feature/Admin/DashboardTest` | F1 | Pendiente |
| RF-40 | `resources/views/history/` | T-340 | `tests/Feature/Booking/HistoryTest` | F3 | Pendiente |
| RF-41 | `Application/Privacy/ExportCustomerData`/`AnonymizeCustomer` | T-341 | `tests/Feature/Privacy/AnonymizeCustomerTest` | F3 | Pendiente |

---

## 3. Requisitos no funcionales

| Req. | Módulo / mecanismo | Tarea | Prueba / verificación | Estado |
|---|---|---|---|---|
| RNF-01 | Reverb, `emitted_at`, monitor sintético | T-008, T-203, T-206, T-207, T-344 | `spikes/t008/latency-40.json` (p95 18,820 ms en local) + `tests/Load/ws-latency.js` (p95 < 200 ms) | En curso (F0; carga real pendiente) |
| RNF-02 | Consultas indexadas, `GetAvailability`, `ConfirmAppointment` | T-133, T-171, T-207 | k6: disponibilidad p95 < 300 ms; confirmación p95 < 600 ms | Pendiente |
| RNF-03 | `RedisSlotHoldStore` + `FOR UPDATE` | T-141 | `tests/Concurrency/ConcurrentBookingTest` | Pendiente |
| RNF-04 | `TenantScope`, canales autorizados | T-110 | `tests/Integration/Tenancy/TenantIsolationTest` | Pendiente |
| RNF-05 | Despliegue, monitoreo, alertas | T-170 | Monitor de disponibilidad en *staging*/producción | Pendiente |
| RNF-06 | Página de reserva Blade/Alpine con ≤ 250 KB en primera carga y TTI ≤ 3 s en 3G rápida (ADR-005); `client_pwa` solo experimental | T-009, T-164, T-165 | `spikes/t009/` (2,32 MB descartan Flutter Web) + Lighthouse CI/WebPageTest sobre la página Blade + Playwright E2E | En curso (F1; presupuesto verificado en T-164) |
| RNF-07 | `barber_app/.../chair_mode`, `fadespace_ui` | T-220, T-223, T-225 | *Golden tests* + prueba manual con cronómetro | Pendiente |
| RNF-08 | Layouts responsive, apps Android 8+/iOS 15+ | T-012, T-150, T-229, T-343 | Checklist 360 px y dispositivos reales | Pendiente |
| RNF-09 | `fadespace_ui`, vistas Blade/Livewire | T-343 | Checklist WCAG 2.1 AA + pruebas de semántica | Pendiente |
| RNF-10 | Sanctum, `RateLimiter`, TLS/WSS | T-108, T-342 | `tests/Feature/Auth/*`, checklist OWASP ASVS | Pendiente |
| RNF-11 | Consentimiento, anonimización, minimización | T-139, T-341 | `tests/Feature/Privacy/*` + revisión documental | Pendiente |
| RNF-12 | `RequestContext`, logs JSON, métricas | T-014, T-206 | `tests/Feature/Observability/*` (formato JSON y enmascarado) + alertas configuradas | En curso (F0, base; métricas/alertas en F2) |
| RNF-13 | Pint, Larastan, `flutter analyze`, cobertura | T-005, T-011 | `composer quality` y `melos exec … flutter test` en verde + pipeline de CI remoto | Cumple en F0 (run 44215818457 verde; cobertura formal llega con F1) |
| RNF-14 | Índices, `preventLazyLoading`, *eager loading* | T-005, T-130, T-133 | `preventLazyLoading` activo en `EloquentServiceProvider`; `tests/Feature/Performance/NoLazyLoadingTest` + `EXPLAIN` en F1 | En curso (F0; índices en F1) |
| RNF-15 | Degradación segura sin Redis; sondeo | T-208, T-228, T-344 | `tests/Integration/Resilience/RedisDownTest` (ESC-25) | Pendiente |
| RNF-16 | l10n `es-CO`, `COP`, `America/Bogota` | T-012, T-106 | ARB `es`/`es_CO` + `flutter gen-l10n`; `TenantSettings` en F1 | En curso (F0; tenant settings en F1) |
| RNF-17 | Respaldos MySQL y restauración | T-170, T-345 | Simulacro de restauración documentado | Pendiente |
| RNF-18 | Aplicación *stateless*, Reverb con Redis | T-010, T-100, T-201 | `compose.yaml` (6 servicios, *healthchecks*) + prueba con 2 nodos | Cumple en local (T-100: stack, *seed* y Reverb validados; escalado en T-201) |
| RNF-19 | `X-Client-Version`, `/api/v1`, OpenAPI | T-221, T-345 | `tests/Feature/Api/ClientVersionTest` + contrato OpenAPI | Pendiente |
| RNF-20 | Migraciones expandir → contraer | T-011, T-345 | Workflow de CI definido; revisión en CI y *runbook* de despliegue | En curso (F0; migraciones en F1) |

---

## 4. Reglas de negocio

| Regla | Descripción corta | Requisito(s) | Tarea(s) | Escenario |
|---|---|---|---|---|
| RN-01 | `tenant_id` y *scope* en toda consulta | RF-02 | T-102 | ESC-07 |
| RN-02 | Dominio único y válido | RF-01 | T-101 | — |
| RN-03 | Teléfonos en E.164, únicos por tenant | RF-04, RF-14 | T-107, T-131 | — |
| RN-04 | UTC + `scheduled_date` local | RF-08, RF-15 | T-130, T-131 | — |
| RN-05 | Baja lógica con historial | RF-04, RF-05 | T-111, T-120 | — |
| RN-06 | *Snapshot* de precio y duración | RF-05, RF-11 | T-130, T-140 | ESC-01 |
| RN-07 | Cuadrícula de franjas configurable | RF-06, RF-08 | T-121, T-132 | — |
| RN-08 | Duración ocupada = Σ duración + mayor *buffer* | RF-08 | T-132 | — |
| RN-09 | Sin traslapes de citas ni bloqueos | RF-07, RF-11 | T-122, T-132, T-140 | ESC-04 |
| RN-10 | Horario y antelación mínima/máxima | RF-06, RF-08 | T-121, T-132 | — |
| RN-11 | Un *hold* por sesión, TTL 180 s | RF-09 | T-135, T-136 | ESC-02, ESC-03 |
| RN-12 | El *hold* no es una cita | RF-09, RF-11 | T-136, T-140 | ESC-03 |
| RN-13 | Confirmación bajo `FOR UPDATE` | RF-11 | T-140, T-141 | ESC-04 |
| RN-14 | "Primer disponible" | RF-12 | T-134 | ESC-06 |
| RN-15 | `Idempotency-Key` en POST críticos | RF-11, RF-20, RF-23, RF-30 | T-140, T-212, T-241 | ESC-26 |
| RN-16 | Ventana de cancelación | RF-13 | T-121, T-143 | ESC-18 |
| RN-17 | Transiciones válidas de estado | RF-15 | T-142 | ESC-24 |
| RN-18 | Citas `pending` y su expiración | RF-15 | T-145 | — |
| RN-19 | Un solo `in_chair` por barbero | RF-15, RF-19 | T-142, T-223 | ESC-08 |
| RN-20 | Gracia y sugerencia de `no_show` | RF-16 | T-144, T-249 | — |
| RN-21 | Bloqueo rápido sin traslapes | RF-21 | T-226 | ESC-15 |
| RN-22 | OTP: 6 dígitos, 5 min, 5 intentos | RF-10 | T-137 | ESC-05 |
| RN-23 | Límites de envío de OTP | RF-10 | T-137 | ESC-23 |
| RN-24 | Token de cliente restringido; dispositivo 30 días | RF-10, RF-13 | T-138 | ESC-07 |
| RN-25 | Consentimiento de datos y *opt-in* WhatsApp | RF-14, RF-35 | T-139, T-312 | — |
| RN-26 | *Walk-in* como cita con `queue_position` | RF-23 | T-240, T-241 | ESC-12 |
| RN-27 | FIFO y hueco que cabe completo | RF-23 | T-240 | ESC-12, ESC-13 |
| RN-28 | Recalculo de espera estimada | RF-24 | T-240, T-242 | ESC-14 |
| RN-29 | TV solo lectura y datos minimizados | RF-25 | T-243, T-245 | ESC-14 |
| RN-30 | Cobro solo desde `in_chair`, atómico | RF-20 | T-224 | ESC-09 |
| RN-31 | `total = barber + shop` | RF-29 | T-211 | ESC-09 |
| RN-32 | Redondeo *half-up* | RF-29 | T-211 | ESC-09 |
| RN-33 | Estrategia `percentage` | RF-29 | T-211 | ESC-09 |
| RN-34 | Estrategia `fixed_service` | RF-29 | T-211 | ESC-10 |
| RN-35 | Estrategia `chair_rental` | RF-29, RF-32 | T-211, T-321 | ESC-11 |
| RN-36 | *Snapshot* de la regla en la transacción | RF-30 | T-210, T-212 | — |
| RN-37 | Transacciones inmutables, reversos | RF-30 | T-210, T-213 | ESC-16 |
| RN-38 | Cierre de caja irreversible | RF-32 | T-322 | ESC-17 |
| RN-39 | Efectivo esperado vs. contado | RF-31, RF-32 | T-214, T-322 | ESC-17 |
| RN-40 | Métodos de pago configurables | RF-06, RF-20 | T-121, T-225 | — |
| RN-41 | Reglas del rescate de huecos | RF-34 | T-302, T-303, T-304 | ESC-19 |
| RN-42 | Primera aceptación gana | RF-34 | T-306 | ESC-19 |
| RN-43 | Ventana horaria y *opt-out* | RF-35 | T-304, T-312 | — |
| RN-44 | Límites por plan | RF-04, RF-37 | T-111, T-330 | ESC-20 |
| RN-45 | Tenant suspendido | RF-36, RF-37 | T-103, T-332 | — |
| RN-46 | Eventos auditables | RF-38 | T-146, T-244 | — |

---

## 5. Historias de usuario → requisitos

| Historia | Requisitos | Fase |
|---|---|---|
| US-01 | RF-10, RF-11 | F1 |
| US-02 | RF-08, RF-12 | F1 |
| US-03 | RF-09 | F1 |
| US-04 | RF-13 | F1 |
| US-05 | RF-04, RF-05, RF-06, RF-07 | F1 |
| US-06 | RF-17, RF-39 | F1 |
| US-07 | RF-18 | F2 |
| US-08 | RF-19 | F2 |
| US-09 | RF-20 | F2 |
| US-10 | RF-21 | F2 |
| US-11 | RF-22 | F2 |
| US-12 | RF-23 | F2 |
| US-13 | RF-25 | F2 |
| US-14 | RF-26 | F2 |
| US-15 | RF-29, RF-30 | F2 |
| US-16 | RF-31, RF-32 | F3 |
| US-17 | RF-32 | F3 |
| US-18 | RF-34 | F3 |
| US-19 | RF-35 | F3 |
| US-20 | RF-36 | F3 |
| US-21 | RF-38 | F1 |
| US-22 | RF-40 | F3 |

---

## 6. Criterios Gherkin → fase → verificación

| Escenario | Fase | Requisitos | Prueba principal | Estado |
|---|---|---|---|---|
| ESC-01 Reserva Zero-Login exitosa | F1 | RF-08…11 | `tests/Feature/Booking/ZeroLoginBookingTest`, Playwright (T-165) | Pendiente |
| ESC-02 El *hold* bloquea la franja | F1 | RF-09 | `tests/Integration/Booking/SlotHoldTest` | Pendiente |
| ESC-03 El *hold* expira a los 180 s | F1 | RF-09 | `tests/Integration/Booking/SlotHoldTest` | Pendiente |
| ESC-04 Concurrencia sin overbooking | F1 | RF-11 | `tests/Concurrency/ConcurrentBookingTest` | Pendiente |
| ESC-05 OTP inválido o vencido | F1 | RF-10 | `tests/Feature/Booking/OtpTest` | Pendiente |
| ESC-06 Primer disponible | F1 | RF-12 | `tests/Unit/Domain/Scheduling/FirstAvailableSelectorTest` | Pendiente |
| ESC-07 Aislamiento multi-tenant | F1 | RF-02 | `tests/Integration/Tenancy/TenantIsolationTest` | Pendiente |
| ESC-08 Cliente en Silla en un toque | F2 | RF-19 | `tests/Feature/Chair/StartServiceTest` | Pendiente |
| ESC-09 Cobro con comisión porcentual | F2 | RF-20, RF-29 | `tests/Feature/Chair/CompleteAndChargeTest` | Pendiente |
| ESC-10 Comisión fija por servicio | F2 | RF-29 | `tests/Unit/Domain/Billing/CommissionEngineTest` | Pendiente |
| ESC-11 Alquiler de silla en el cierre | F3 | RF-29, RF-32 | `tests/Unit/Domain/Billing/CashClosingCalculatorTest` | Pendiente |
| ESC-12 *Walk-in* insertado en un hueco | F2 | RF-23 | `tests/Unit/Domain/Queue/WalkInPlacerTest` | Pendiente |
| ESC-13 *Walk-in* sin hueco suficiente | F2 | RF-23 | `tests/Unit/Domain/Queue/WalkInPlacerTest` | Pendiente |
| ESC-14 Pantalla de TV en tiempo real | F2 | RF-24, RF-25, RF-27 | `tests/Realtime/TvBoardTest`, `tests/Load/ws-latency.js` | Pendiente |
| ESC-15 Bloqueo rápido de tiempo | F2 | RF-21 | `tests/Feature/Chair/QuickBlockTest` | Pendiente |
| ESC-16 Transacciones inmutables y reverso | F2 | RF-30 | `tests/Feature/Billing/ReversalTest` | Pendiente |
| ESC-17 Cierre de caja | F3 | RF-32 | `tests/Feature/Billing/CloseCashRegisterTest` | Pendiente |
| ESC-18 Cancelación por el cliente en ventana | F1 | RF-13 | `tests/Feature/Booking/CustomerCancelTest` | Pendiente |
| ESC-19 Rescate de hueco muerto | F3 | RF-34 | `tests/Feature/Rescue/GapOfferTest` | Pendiente |
| ESC-20 Límite del plan | F3 | RF-37 | `tests/Feature/Tenancy/PlanLimitsTest` | Pendiente |
| ESC-21 Reconexión y resincronización | F2 | RF-28 | `tests/Feature/Realtime/SnapshotTest`, `test/realtime/reconnect_test.dart` | Pendiente |
| ESC-22 Permisos por rol | F1 | RF-03 | `tests/Feature/Auth/RolePermissionsTest` | Pendiente |
| ESC-23 Límite de envíos de OTP | F1 | RF-10 | `tests/Feature/Booking/OtpRateLimitTest` | Pendiente |
| ESC-24 Transición de estado inválida | F1 | RF-15 | `tests/Unit/Domain/Scheduling/AppointmentStateMachineTest` | Pendiente |
| ESC-25 Redis no disponible | F2 | RF-28, RNF-15 | `tests/Integration/Resilience/RedisDownTest` | Pendiente |
| ESC-26 Idempotencia al cobrar | F2 | RF-30 | `tests/Feature/Billing/IdempotentChargeTest` | Pendiente |

---

## 7. Cobertura por fase

| Fase | Requisitos funcionales | Escenarios | Épicas | Release gate |
|---|---|---|---|---|
| F0 — Cimientos | — | — | E-01 | G1, G2 |
| F1 — MVP Core | RF-01…RF-17, RF-38, RF-39 (19) | ESC-01…07, 18, 22, 23, 24 (11) | E-02…E-07 | G3 (F1) |
| F2 — Tiempo real y movilidad | RF-18…RF-31 (14) | ESC-08…10, 12…16, 21, 25, 26 (11) | E-08…E-12 | G3 (F2) |
| F3 — Automatización y monetización | RF-32…RF-37, RF-40, RF-41 (8) | ESC-11, 17, 19, 20 (4) | E-13…E-17 | G3 (F3), G4 |
| **Total** | **41** | **26** | | |

### 7.1 Estado de E-01 (F0) al 2026-11-17

| Tarea | Estado | Evidencia principal | Pendiente |
|---|---|---|---|
| T-001…T-004 | `[x]` | `00-constitucion.md`, `01-spec.md`, `02-plan.md`, `03-tasks.md`, este documento | — |
| T-005 | `[x]` | `backend/`, `composer quality` en verde (Pint, Larastan 8, audit, 14 pruebas) | — |
| T-006 | `[x]` | `backend/tests/Architecture/LayersTest.php` | — |
| T-007 | `[x]` | Acta G1/G2 del 2026-11-17 (`01-spec.md` §12/§14, `02-plan.md` §14) | — |
| T-008 | `[~]` | `spikes/t008/latency-40.json`, ADR-004 | Dispositivo real y carga (T-206/T-207) |
| T-009 | `[x]` | `spikes/t009/*`, ADR-005 aplicado | Presupuesto de la página Blade en T-164 (F1) |
| T-010 | `[x]` | `compose.yaml`, `infra/docker/*`; stack de 6 servicios arriba, `migrate:fresh --seed` y `/api/v1/health` 200 (T-100) | — |
| T-011 | `[x]` | `.github/workflows/ci.yml`, `infra/github/branch-protection.json`, `docs/ci.md`; CI verde (run 44215818457) y `main` protegida | — |
| T-012 | `[x]` | `mobile/` (6 paquetes), `flutter analyze` limpio, 25 pruebas | — |
| T-013 | `[x]` | `docs/adr/ADR-001…007`, `ADR-010` | — |
| T-014 | `[x]` | `app/Infrastructure/Observability/`, `/api/v1/health` | — |
| T-100 | `[x]` | Docker Compose, CI remoto y protección de rama verificados el 2026-11-17 | Primer PR real bajo la política |

---

## 8. Registro de cambios

| Versión | Fecha | Cambio | Autor |
|---|---|---|---|
| 1.0 | 2026-11-14 | Versión inicial de la documentación SEDD de FadeSpace | Diego Alejandro Zamora Gallego |
| 1.1 | 2026-11-14 | Avance de E-01: T-005, T-006, T-012, T-013 y T-014 completadas; T-008…T-011 en curso con evidencia en `spikes/`; ADR-001…007 y 010 registrados | Diego Alejandro Zamora Gallego |
| 1.2 | 2026-11-17 | Cierre de E-01: T-007 aprobada (G1/G2); T-009 con ADR-005 aplicado; T-160…T-165 re-planificadas a Blade/Alpine; alta de T-100 (traslado de T-010/T-011); RNF-06 pasa a ≤ 250 KB/TTI ≤ 3 s | Diego Alejandro Zamora Gallego |
| 1.3 | 2026-11-17 | T-100 completada: T-010 y T-011 pasan a `[x]`; CI remoto verde y `main` protegida con 3 checks obligatorios; C-08, C-15, RNF-13 y RNF-18 actualizados | Diego Alejandro Zamora Gallego |
