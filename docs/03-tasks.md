# Tareas — FadeSpace

**Versión:** 1.2  
**Estado:** F0 cerrada en G2 (2026-11-17) · infraestructura validada en entorno real (T-100) · F1–F3 pendientes  
**Autor:** Diego Alejandro Zamora Gallego  
**Depende de:** `02-plan.md`

Leyenda: `[ ]` pendiente · `[~]` en curso o validado solo parcialmente (el pendiente se indica en la propia tarea) · `[x]` completada.  
Cada tarea indica entre paréntesis los requisitos que cubre. El primer dígito del número de tarea indica la fase (`T-0xx` F0, `T-1xx` F1, `T-2xx` F2, `T-3xx` F3). Las tareas se ejecutan en orden dentro de su épica salvo que se indique `Dep.`.

**Reglas de uso:**

- Una tarea no se marca `[x]` hasta cumplir la Definición de Hecho de `00-constitucion.md` §10.
- Al completar una tarea se actualiza su fila en `04-traceability.md`.
- Una tarea nueva requiere control de cambios (constitución §14).

---

## F0 — Cimientos

### E-01 Fundaciones, documentación y plataforma de desarrollo

- [x] **T-001** Redactar la constitución (`00-constitucion.md`).
- [x] **T-002** Redactar la especificación (`01-spec.md`).
- [x] **T-003** Redactar el plan (`02-plan.md`).
- [x] **T-004** Redactar tareas y matriz de trazabilidad (`03-tasks.md`, `04-traceability.md`).
- [x] **T-005** Crear el monorepo `fadespace/` y el *scaffold* Laravel: PHP ≥ 8.3, `strict_types`, Pint (PSR-12), Larastan nivel 8, Pest, `Model::preventLazyLoading()` fuera de producción. _(C-08, RNF-13, RNF-14)_
      → `backend/` con PHP **8.4** (Pest 5 exige `^8.4`; ver ADR-010), `pint.json` con `declare_strict_types`, `phpstan.neon` nivel 8, Pest 5 con pruebas de arquitectura y `preventLazyLoading` en `EloquentServiceProvider`. `composer quality` en verde.
- [x] **T-006** Pruebas de arquitectura (Pest Arch / Deptrac): `Domain` no importa `Illuminate`, `Application` no importa `Http`, Eloquent solo en `Infrastructure`. Dep. T-005. _(C-07)_
      → `backend/tests/Architecture/LayersTest.php` en verde.
- [x] **T-007** **Aprobación G1 y G2:** revisión humana de constitución, spec y plan; resolver o aceptar las preguntas abiertas OQ-01…OQ-07. _(C-16)_
      → **Aprobada el 2026-11-17** por el autor: G1 y G2 firmadas; OQ-01…OQ-05 y OQ-07 aceptadas y OQ-06 resuelta con ADR-005 (`01-spec.md` §12, acta en §14).
- [~] **T-008** *Spike* de tiempo real: Reverb + cliente Flutter (móvil y web); medir latencia commit → cliente con `emitted_at`; registrar **ADR-004**. _(RNF-01, C-09)_
      → Medido en local: 40/40 eventos, p50 **17,808 ms**, p95 **18,820 ms** (`spikes/t008/`), ADR-004 escrito y cliente en `fadespace_realtime`. **Pendiente:** validación en dispositivo real y bajo carga (T-206/T-207).
- [x] **T-009** *Spike* de peso y TTI de Flutter Web en 3G; decidir **ADR-005** (Flutter Web vs. página de reserva liviana). _(RNF-06, OQ-06)_
      → Medido: primera carga real **2,32 MB** (> 2 MB de RNF-06), FCP 4,67 s, sin LCP/TTI medibles; variante wasm 1,90 MB como mejor caso (`spikes/t009/`). **ADR-005 ratificado el 2026-11-14 y aplicado el 2026-11-17**: página Blade/Alpine para el embudo público; el presupuesto definitivo (≤ 250 KB, TTI ≤ 3 s) se verifica en T-164 (F1).
- [x] **T-010** Docker Compose local: PHP-FPM, Nginx, MySQL 8, Redis 7, Mailpit, Reverb. Dep. T-005. _(RNF-18)_
      → `compose.yaml` + `infra/docker/{php,nginx}` (6 servicios, *healthchecks*, redes y volúmenes). **Validada el 2026-11-17 en T-100:** `docker compose config` OK, `up -d --build` con los 6 servicios arriba (MySQL, Redis y Mailpit *healthy*), `migrate:fresh --seed` correcto y `GET /api/v1/health` → **200** con `database` y `cache` en `up`. La validación real corrigió dos defectos: falta de `pcntl` en la imagen PHP (Reverb no arrancaba) y resolución DNS estática en Nginx (502 al recrear `app`).
- [x] **T-011** Pipeline de CI: Pint, Larastan, Pest, `composer audit`, `flutter analyze`, `flutter test`; protección de ramas. Dep. T-005, T-012. _(C-08, C-15, RNF-13)_
      → `.github/workflows/ci.yml` (jobs backend/mobile/infra), política de ramas (`infra/github/branch-protection.json` + `scripts/apply-branch-protection.ps1`) y `docs/ci.md`. **Validada el 2026-11-17 en T-100:** CI remoto **verde** en `main` ([run 44215818457](https://github.com/BloxyBlocks/FadeSpace/actions/runs/44215818457)) y protección aplicada y verificada por API: 3 *status checks* obligatorios, *strict*, `enforce_admins`, sin *force push* ni borrado, historial lineal y conversaciones resueltas. Aprobaciones de PR = **0** mientras exista un solo *maintainer* (GitHub no permite autoaprobar); se elevará a 1 al incorporar un segundo.
- [x] **T-012** *Scaffold* Flutter con `melos`: `apps/barber_app`, `apps/client_pwa`, `packages/{fadespace_core, fadespace_api, fadespace_realtime, fadespace_ui}`; `very_good_analysis`; l10n `es-CO`. _(C-10, RNF-16)_
      → Melos 8.10.1 + *pub workspaces*; 6 paquetes; `flutter analyze` limpio y pruebas en verde (25 pruebas). l10n `es` + `es_CO` con `flutter gen-l10n`. Flutter 3.50 exige `material_ui`/`cupertino_ui` (ADR-010).
- [x] **T-013** Redactar ADR-001, 002, 003, 006 y 007 (multi-tenant, autenticación, locking, proveedor OTP, estado/navegación Flutter). _(C-17)_
      → `docs/adr/` con ADR-001, 002, 003, 006, 007, más ADR-004, ADR-005 y ADR-010 (dependencias nuevas) y el índice `docs/adr/README.md`.
- [x] **T-014** Observabilidad base: `RequestContext` (`request_id`, `tenant_id`), logs JSON con enmascarado de teléfonos, endpoint de salud. _(C-14, RNF-12)_
      → `Infrastructure/Observability/` (`RequestContext`, `AssignRequestContext`, `ConfigureStructuredLogging`, `MaskSensitiveData`, `RequestContextProcessor`, `HealthChecker`) y `GET /api/v1/health`; cubierto por 6 pruebas.

**Criterio de salida F0:** G1 y G2 aprobadas; *spikes* T-008 y T-009 resueltos con ADR; CI en verde y
protección de rama aplicada (validado en T-100 el 2026-11-17).

> **Estado al 2026-11-17:** **E-01 cerrada y validada en entorno real.** G1/G2 firmadas (T-007) y OQ-01…OQ-07
> resueltas. T-005, T-006, T-009, T-010, T-011 y T-012…T-014 completadas; **T-100 completada**. T-008 queda `[~]`
> por la validación en dispositivo real y bajo carga (T-206/T-207). El CI remoto está verde y `main` está protegida;
> queda abierta la verificación del primer PR real bajo la nueva política.

---

## F1 — MVP Core

- [x] **T-100** *(precondición de F1)* Validar la infraestructura de F0 en un entorno real: `docker compose config`,
  `docker compose up -d --build` y `php artisan migrate --seed`; crear el repositorio remoto, ejecutar el pipeline y
  aplicar la protección de rama con `scripts/apply-branch-protection.ps1`. Cierra T-010 y T-011. _(RNF-18, C-08, C-15)_
      → **Completada el 2026-11-17.** Repositorio público `BloxyBlocks/FadeSpace`; CI verde en `accd5ed`; stack local
      arriba con migraciones y *seed*; `/api/v1/health` → 200; protección de `main` aplicada y verificada por API.
      La ejecución real detectó y corrigió tres defectos que CI no cubría: *factory* de `User` no resoluble por el
      *namespace* del modelo, extensión `pcntl` ausente (Reverb) y Nginx con IP obsoleta de `app` tras recrearlo.

### E-02 Multi-tenancy e identidad

- [ ] **T-101** Migración, modelo y *factory* de `tenants` (plan, estado, `settings` JSON, dominio único). _(RF-01, RN-02)_
- [ ] **T-102** *Trait* `BelongsToTenant` + `TenantScope` global + asignación automática de `tenant_id`; ignorar `tenant_id` enviado por el cliente. _(RF-02, RN-01, C-03)_
- [ ] **T-103** Middleware `ResolveTenant` (dominio → tenant, con caché `tenant:domain:{domain}`) y `EnsureTenantActive`. _(RF-02, RN-45)_
- [ ] **T-104** `TenantContext` por petición y propagación a *jobs* (`TenantAwareJob`). _(RF-02, C-03)_
- [ ] **T-105** `TenantCache`: prefijo obligatorio `t:{tenantId}:` en claves Redis, caché y *locks*. _(C-03, C-13)_
- [ ] **T-106** Comando `tenant:create` (tenant + administrador inicial + configuración por defecto: `America/Bogota`, `COP`, cuadrícula 15 min). _(RF-01, RNF-16)_
- [ ] **T-107** Migración de `users` (rol, `commission_type`, `commission_rate`, `UNIQUE(tenant_id, phone)`) e instalación de Sanctum. _(RF-03, RF-04, RN-03)_
- [ ] **T-108** Autenticación del personal: `login`, `logout`, `me`, revocación de dispositivos, *throttling* y registro en auditoría. _(RF-03, RNF-10)_
- [ ] **T-109** *Policies* por rol (`admin`, `barber`) y verificación de pertenencia al tenant en cada caso de uso. _(RF-03, ESC-22)_
- [ ] **T-110** Suite de **aislamiento multi-tenant** (HTTP, caché, colas, canales) en CI. _(RNF-04, ESC-07, C-03)_
- [ ] **T-111** Gestión de barberos (API): alta, edición, comisión, activación/desactivación con reasignación de citas futuras; `PlanGate` básico (`free_chair` = 1 barbero). _(RF-04, RN-05, RN-44)_

### E-03 Catálogo, horarios y configuración

- [ ] **T-120** Migración, CRUD y caché (`t:{tid}:catalog`) de `services` con invalidación explícita. _(RF-05, RN-06)_
- [ ] **T-121** `TenantSettings`: esquema validado (horario de atención, zona horaria, marca, cuadrícula, antelación mínima/máxima, ventana de cancelación, gracia, métodos de pago) + endpoints. _(RF-06, RN-07, RN-10, RN-16, RN-40)_
- [ ] **T-122** Migraciones y CRUD de `barber_schedules` y `time_blocks` (validación de traslapes y de horario). _(RF-07, RN-09)_
- [ ] **T-123** *Seeders* de demostración: tenant, administrador, 3 barberos con distintas comisiones, servicios y horarios. _(C-15)_

### E-04 Disponibilidad y reserva Zero-Login

- [ ] **T-130** Migraciones de `customers`, `appointments` y `appointment_services` con los índices obligatorios `(tenant_id, barber_id, scheduled_date, status)`, `(tenant_id, customer_id, scheduled_start)` y `(tenant_id, status, scheduled_start)`. _(RF-14, RF-15, RNF-14)_
- [ ] **T-131** Dominio: `Money` (`bcmath`), `Phone` (E.164), `TimeRange`, `Clock`. _(C-06, C-18, RN-03)_
- [ ] **T-132** `AvailabilityCalculator` + `SlotGrid` puros (citas, bloqueos, horarios, duración + *buffer*, antelación) con pruebas unitarias exhaustivas. Dep. T-131. _(RF-08, RN-07…RN-10)_
- [ ] **T-133** Caso de uso `GetAvailability` + endpoint `GET /public/availability` (consultas indexadas, sin N+1). Dep. T-132. _(RF-08, RNF-02)_
- [ ] **T-134** `FirstAvailableSelector` ("Primer disponible", desempate por menor carga). _(RF-12, RN-14, ESC-06)_
- [ ] **T-135** `RedisSlotHoldStore` con *script* Lua atómico (crear, liberar, índice por barbero/día, TTL 180 s). _(RF-09, RN-11, D-04)_
- [ ] **T-136** Casos de uso `CreateSlotHold`/`ReleaseSlotHold` y endpoints; la disponibilidad excluye *holds* vivos. Dep. T-135. _(RF-09, ESC-02, ESC-03)_
- [ ] **T-137** OTP: `RedisOtpStore` (*hash*, intentos), interfaz `OtpChannel`, `SmsOtpChannel` (proveedor según ADR-006) y `LogChannel` para local; límites 3/h por teléfono y 10/h por IP. _(RF-10, RN-22, RN-23)_
- [ ] **T-138** Endpoints `otp/request` y `otp/verify`; emisión de token de cliente (*ability* `customer:booking`, dispositivo recordado 30 días). Dep. T-137. _(RF-10, RN-24, ESC-05, ESC-23)_
- [ ] **T-139** `CustomerResolver`: *upsert* por teléfono, registro de consentimiento de datos y de *opt-in* de WhatsApp. _(RF-14, RN-25)_
- [ ] **T-140** `ConfirmAppointment`: transacción con `SELECT … FOR UPDATE` sobre el barbero, revalidación de traslapes y bloqueos, *snapshot* de servicios, consumo del *hold*, `Idempotency-Key`, auditoría y evento `afterCommit`. Dep. T-130, T-136, T-139. _(RF-11, RN-12, RN-13, RN-15, ESC-01)_
- [ ] **T-141** **Prueba de concurrencia:** 50 confirmaciones simultáneas a una misma franja → exactamente 1 éxito y 49 `409`. Dep. T-140. _(RNF-03, ESC-04, C-05)_
- [ ] **T-142** `AppointmentStateMachine` con transiciones válidas y pruebas de transiciones inválidas. _(RF-15, RN-17, RN-19, ESC-24)_
- [ ] **T-143** Cancelación y reprogramación por el cliente (token) con ventana de cancelación configurable. Dep. T-142. _(RF-13, RN-16, ESC-18)_
- [ ] **T-144** Cancelación por el personal, `MarkNoShow` y sugerencia de `no_show` tras el tiempo de gracia (*job*). Dep. T-142. _(RF-16, RN-20)_
- [ ] **T-145** Comando programado `appointments:expire-pending` (citas `pending` > 60 min). _(RN-18)_
- [ ] **T-146** Auditoría base: `audit_logs` y *listener* transaccional para inicio de sesión, cambios de comisión/precio, cancelaciones y revocaciones. _(RF-38, RN-46, C-14)_

### E-05 Dashboard administrativo

- [ ] **T-150** *Layout* Livewire/Alpine, autenticación web del administrador y navegación responsive. Dep. T-108. _(RF-39, RNF-08)_
- [ ] **T-151** Vistas de barberos, servicios, horarios y configuración del tenant. Dep. T-111, T-120…T-122. _(RF-04…RF-07)_
- [ ] **T-152** Agenda por silla (vista diaria) con creación, movimiento y cancelación manual de citas; reutiliza `ConfirmAppointment`. Dep. T-140, T-143. _(RF-17, RF-39)_
- [ ] **T-153** KPIs del día: citas, ocupación por silla, cancelaciones y no-shows. _(RF-39)_
- [ ] **T-154** Vista de auditoría filtrable (solo administrador). Dep. T-146. _(RF-38, US-21)_

### E-06 Página de reserva del cliente (Zero-Login, Blade/Alpine)

> Re-planificada el 2026-11-17 por ADR-005 (CC-02). `apps/client_pwa` queda como cáscara experimental y el embudo
> público se sirve con Blade + Alpine.

- [ ] **T-160** Vistas Blade/Alpine de la página de reserva: layout y tema (tokens CSS desde `fadespace_ui`), resolución del tenant por dominio, cliente de API con `Idempotency-Key` y manejo de errores de dominio. Dep. T-012, T-009. _(RF-10, C-10, RNF-06)_
- [ ] **T-161** Flujo de reserva server-rendered: servicio(s) → barbero / "Primer disponible" → fecha y franja → *hold* con cuenta regresiva visible (Alpine). Dep. T-133, T-136. _(RF-08, RF-09, RF-12)_
- [ ] **T-162** Pantalla de datos (nombre, teléfono, consentimiento), verificación OTP y confirmación de cita; manejo de `SLOT_TAKEN` y `HOLD_EXPIRED` conservando los datos. Dep. T-138, T-140. _(RF-10, RF-11)_
- [ ] **T-163** "Mi cita": ver, cancelar y reprogramar; dispositivo recordado (omite OTP). Dep. T-143. _(RF-13, US-04)_
- [ ] **T-164** Presupuesto de carga de la página de reserva: ≤ **250 KB** en la primera carga y **TTI ≤ 3 s** en 3G rápida (sustituye los 2 MB/6 s de Flutter Web), automatizado en CI con Lighthouse y verificado en WebPageTest con dispositivo real. _(RNF-06)_
- [ ] **T-165** E2E con Playwright sobre la página Blade/Alpine: reserva completa de cliente recurrente en ≤ 15 s. _(RNF-06, ESC-01)_

### E-07 Release F1

- [ ] **T-170** ADR-009 y despliegue a *staging*; respaldos diarios de MySQL con restauración probada; TLS. _(RNF-05, RNF-17)_
- [ ] **T-171** Pruebas de carga F1 (disponibilidad p95 < 300 ms; confirmación p95 < 600 ms). _(RNF-02)_
- [ ] **T-172** Verificación Gherkin F1 (ESC-01…07, 18, 22, 23, 24) y **release gate G3 (F1)**. _(C-16)_

**Criterio de salida F1:** un tenant de prueba reserva de punta a punta sin overbooking; la suite de aislamiento y la de concurrencia en verde.

---

## F2 — Tiempo real y movilidad

### E-08 Tiempo real (Laravel Reverb)

- [ ] **T-201** Instalar y configurar Reverb (aplicaciones, escalado horizontal con Redis) y Supervisor. Dep. T-008. _(RF-27, RNF-18)_
- [ ] **T-202** Autorización de canales tenant-scoped: `tenant.{id}.admin`, `tenant.{id}.barber.{id}`, `tenant.{id}.queue`, `tenant.{id}.availability.{id}`. _(RF-27, C-03)_
- [ ] **T-203** Eventos de dominio → *broadcasts* `afterCommit` con *payload* versionado (`version`, `emitted_at`, `tenant_id`): `AppointmentConfirmed`, `AppointmentCancelled`, `AppointmentStatusChanged`, `WalkInQueued`, `QueueUpdated`, `ChairBlocked`, `TransactionRegistered`. _(RF-27, D-05)_
- [ ] **T-204** Autorización de canales para token de cliente y *display token*. _(RF-27, RN-29)_
- [ ] **T-205** Endpoints de *snapshot* (agenda del barbero, fila, disponibilidad) para resincronización tras reconexión. _(RF-28, ESC-21)_
- [ ] **T-206** Monitor sintético de latencia (`emitted_at` vs. recepción) y pruebas de entrega de eventos. _(RNF-01, RNF-12)_
- [ ] **T-207** Prueba de carga WebSocket: 1.000 conexiones concurrentes con p95 < 200 ms. Dep. T-203. _(RNF-01, RNF-02)_
- [ ] **T-208** Degradación segura: sondeo cada 15 s cuando falla el WebSocket o Redis. _(RNF-15, ESC-25)_

### E-09 Motor de comisiones y transacciones

- [ ] **T-210** Migración de `transactions` (solo inserción, `kind`, *snapshot* de regla, `idempotency_key` único por tenant, índices). _(RF-30, RN-36, RN-37)_
- [ ] **T-211** `CommissionEngine` y estrategias `PercentageStrategy`, `FixedServiceStrategy`, `ChairRentalStrategy`; redondeo *half-up*; pruebas de propiedades (`total = barber + shop`). Dep. T-131. _(RF-29, RN-31…RN-35, ESC-09, ESC-10)_
- [ ] **T-212** `RegisterTransaction` con idempotencia y *snapshot* de comisión. Dep. T-210, T-211. _(RF-30, RN-15, RN-36, ESC-26)_
- [ ] **T-213** `ReverseTransaction` (solo administrador): reverso con montos negativos que referencia la original. Dep. T-212. _(RF-30, RN-37, RN-38, ESC-16)_
- [ ] **T-214** `GetCashSummary`: ingresos brutos por barbero, desglose por método y separación efectivo vs. digital. _(RF-31, RN-39)_
- [ ] **T-215** Vista de caja diaria en el dashboard con actualización en vivo. Dep. T-214, T-203. _(RF-31, US-15)_

### E-10 App del barbero (Modo Silla)

- [ ] **T-220** *Scaffold* de `barber_app` con `fadespace_api`, `fadespace_realtime`, `fadespace_ui` y tema de Modo Silla (objetivos ≥ 48 dp, alto contraste). Dep. T-012. _(RF-19, RNF-07, C-10)_
- [ ] **T-221** Login del barbero (dominio + teléfono + contraseña) con token en almacenamiento seguro y detección de versión mínima (`X-Client-Version`). Dep. T-108. _(RF-03, RNF-19)_
- [ ] **T-222** Agenda diaria en vivo (suscripción a `barber.{id}` + *snapshot* inicial). Dep. T-202, T-205. _(RF-18, US-07)_
- [ ] **T-223** `StartService` (backend) y botón **"Cliente en Silla"** (1 toque, UI optimista); impide dos `in_chair` simultáneos. Dep. T-142. _(RF-19, RN-19, ESC-08)_
- [ ] **T-224** `CompleteAndCharge` (backend): en una sola transacción completa la cita, registra la transacción con su comisión e incrementa `visits_count`. Dep. T-212. _(RF-20, RN-30, ESC-09)_
- [ ] **T-225** UI **"Finalizar y Cobrar"**: selector de método de pago (≤ 2 toques) con retroalimentación háptica. Dep. T-224. _(RF-20, RNF-07)_
- [ ] **T-226** `QuickBlock` (backend y UI): valores predefinidos 15/30/60 min; rechaza traslapes con citas confirmadas. _(RF-21, RN-21, ESC-15)_
- [ ] **T-227** Métricas diarias del barbero (endpoint y pantalla de ganancias del día). Dep. T-214. _(RF-22, US-11)_
- [ ] **T-228** Resiliencia de la app: estados en línea / reconectando / sin conexión, reintentos con la misma `Idempotency-Key`, resincronización con *snapshot*. _(RF-28, RNF-15)_
- [ ] **T-229** Distribución interna (APK/Play interno y TestFlight). _(RNF-08)_

### E-11 *Walk-ins*, fila virtual y Pantalla de TV

- [ ] **T-240** `WalkInPlacer` y `WaitTimeEstimator` puros, con pruebas (hueco que cabe, sin hueco, servicio en curso que se excede). _(RF-23, RF-24, RN-26…RN-28)_
- [ ] **T-241** `AddWalkIn` (caso de uso y endpoint) bajo el mismo *lock* que la reserva, con `Idempotency-Key`. Dep. T-240, T-140. _(RF-23, ESC-12, ESC-13)_
- [ ] **T-242** `RecalculateQueue` (*listener* de cambios de estado) y *snapshot* de fila en Redis (`t:{tid}:queue:{date}`). Dep. T-203. _(RF-24, RN-28)_
- [ ] **T-243** Migración `display_devices` y autenticación por *display token* (almacenado como *hash*, revocable). _(RF-25, RN-29)_
- [ ] **T-244** Gestión de dispositivos de TV en el dashboard (crear, ver último acceso, revocar) con auditoría. Dep. T-243. _(RF-25, RN-46)_
- [ ] **T-245** **Pantalla de TV / Kiosco** (Blade + Alpine + Echo): en silla, siguiente, espera estimada; reconexión automática; solo nombre de pila e inicial. Dep. T-204, T-242. _(RF-25, ESC-14)_
- [ ] **T-246** Diálogo "Agregar Walk-in" en la app del barbero. Dep. T-241. _(RF-23, US-12)_
- [ ] **T-247** Registro de *walk-ins* desde el dashboard (recepción). Dep. T-241. _(RF-23)_
- [ ] **T-248** Página web (Blade/Alpine): estado de fila / "mi turno" con espera estimada en vivo. Dep. T-204, T-242. _(RF-26, US-14)_
- [ ] **T-249** Sugerencia visual de `no_show` en la agenda del barbero y acción de confirmación. Dep. T-144. _(RF-16, RN-20)_

### E-12 Release F2

- [ ] **T-250** E2E integrado: cliente reserva → barbero inicia en silla → TV se actualiza → cobro → caja del dashboard. _(RF-19…RF-27)_
- [ ] **T-251** Verificación Gherkin F2 (ESC-08…10, 12…16, 21, 25, 26) y **release gate G3 (F2)**. _(C-16)_

**Criterio de salida F2:** flujo silla → cobro → TV con p95 < 200 ms bajo la carga de referencia; app en distribución interna.

---

## F3 — Automatización y monetización

### E-13 Rescate de huecos muertos

- [ ] **T-301** Migración de `gap_offers` (estados `sent`, `accepted`, `expired`, `cancelled`). _(RF-34)_
- [ ] **T-302** `CustomerCycleAnalyzer`: ciclo promedio entre visitas por cliente (≥ 3 visitas). _(RF-34, RN-41)_
- [ ] **T-303** `GapDetector`: huecos ≥ duración del servicio habitual, por cancelación o baja demanda. _(RF-34)_
- [ ] **T-304** `OfferPolicy`: *opt-in*, ±3 días de ciclo, máximo 1 oferta por semana, ventana 7:00–21:00. _(RN-41, RN-43)_
- [ ] **T-305** `DetectGaps` y `SendGapOffer` (*scheduler* cada 5 min + *listener* de `AppointmentCancelled`). Dep. T-301…T-304, T-310. _(RF-34)_
- [ ] **T-306** `AcceptGapOffer`: reutiliza *hold* + *lock*; la primera aceptación gana y cancela las demás. _(RF-34, RN-42, ESC-19)_
- [ ] **T-307** Dashboard: activar/configurar el rescate y métricas de conversión. _(RF-34)_

### E-14 Notificaciones WhatsApp

- [ ] **T-310** `WhatsAppChannel` (WhatsApp Business API) sobre la abstracción de mensajería; *fallback* a SMS. _(RF-35, OQ-03)_
- [ ] **T-311** Plantillas aprobadas: confirmación, recordatorio, oferta de hueco; versionado. _(RF-35)_
- [ ] **T-312** *Opt-in/opt-out*, ventana horaria y límites de envío. _(RF-35, RN-25, RN-43)_
- [ ] **T-313** `notification_logs` y *webhook* de estado de entrega con verificación de firma. _(RF-35)_
- [ ] **T-314** `ScheduleReminders`: recordatorios 24 h y 2 h antes de la cita. _(RF-35)_
- [ ] **T-315** Paquetes prepagados de mensajes (`tenant_addons`) con descuento de saldo. _(RF-35, RF-37)_

### E-15 Cierre de caja y liquidación avanzada

- [ ] **T-320** Migraciones de `cash_closings` y `cash_closing_barbers`. _(RF-32)_
- [ ] **T-321** `CashClosingCalculator`: bruto, comisión, parte del local y **descuento de alquiler** por jornada (`chair_rental`). Dep. T-211. _(RF-32, RN-35, ESC-11)_
- [ ] **T-322** `CloseCashRegister`: efectivo contado vs. esperado, congelamiento (`settled_at`), irreversible, auditoría y evento `CashClosed`. Dep. T-321. _(RF-32, RN-38, RN-39, ESC-17)_
- [ ] **T-323** Vistas de cierre de caja y liquidación por barbero en el dashboard (exportable). _(RF-32, US-16, US-17)_
- [ ] **T-324** Liquidación del barbero visible en la app (día y periodo). _(RF-32, RF-22)_
- [ ] **T-325** Reportes financieros por periodo y exportación CSV. _(RF-33)_

### E-16 Suscripciones SaaS

- [ ] **T-330** Migración de `subscriptions` y `PlanGate`: límites y *features* por plan (matriz validada en OQ-01). _(RF-36, RF-37, RN-44, ESC-20)_
- [ ] **T-331** **ADR-008** e integración con la pasarela de pagos; *webhooks* con verificación de firma. _(RF-36, OQ-04)_
- [ ] **T-332** Estados `active`/`past_due`/`canceled`, periodo de gracia y suspensión del tenant; `EnforcePlanLimits`. Dep. T-330, T-331. _(RF-36, RF-37, RN-45)_
- [ ] **T-333** *Onboarding* autoservicio: alta de tenant, administrador, servicios y horarios iniciales. _(RF-01, RF-36)_
- [ ] **T-334** Activación de add-ons por tenant (WhatsApp). _(RF-37)_

### E-17 Privacidad, calidad y convergencia

- [ ] **T-340** Historial de servicios del cliente en la página web. _(RF-40, US-22)_
- [ ] **T-341** Exportación y anonimización de datos del cliente a solicitud del titular. _(RF-41, RNF-11)_
- [ ] **T-342** Revisión de seguridad (checklist OWASP ASVS nivel 2 básico) y prueba de penetración básica. _(RNF-10)_
- [ ] **T-343** Pasada de accesibilidad y 360 px en apps y página web (escala de texto 1,3×, contraste). _(RNF-08, RNF-09)_
- [ ] **T-344** Pruebas finales de carga y resiliencia (Redis caído, reconexión masiva de WebSockets). _(RNF-01, RNF-15)_
- [ ] **T-345** README, *runbooks*, OpenAPI final y prueba de restauración de respaldo. _(RNF-17, RNF-19, C-17)_
- [ ] **T-346** Convergencia **G4**: todos los escenarios Gherkin verificados, trazabilidad completa y cierre del backlog. _(C-02, C-16)_

**Criterio de salida F3:** todos los escenarios ESC-01…ESC-26 verificados; suscripciones cobrando; G4 aprobada.

---

## Backlog posterior (v1.1+)

- Multi-sucursal.
- Inventario y comisiones por venta de productos.
- Propinas, descuentos y servicios adicionales al cobrar.
- Notificaciones *push* nativas (FCM/APNs) para el barbero.
- Pagos o depósitos en línea de la cita por el cliente.
- Servicios habilitados y duraciones por barbero.
- Panel de plataforma (*super-admin*) de Bloxysoft.
- Reportes avanzados y tablero de retención de clientes.

---

## Registro de cambios

| Versión | Fecha | Cambio |
|---|---|---|
| 1.0 | 2026-11-14 | Versión inicial de la lista de tareas y trazabilidad. |
| 1.1 | 2026-11-17 | Cierre de E-01: T-007 aprobada (G1/G2); T-160…T-165 re-planificadas a Blade/Alpine por ADR-005; alta de T-100 para validar Docker y CI remoto (traslado de T-010/T-011). |
| 1.2 | 2026-11-17 | **T-100 completada:** T-010 y T-011 pasan a `[x]` tras validar Docker Compose, migraciones/*seed*, CI remoto verde y protección de `main` en GitHub. |
