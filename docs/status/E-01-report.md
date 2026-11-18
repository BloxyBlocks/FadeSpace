# Informe de cierre — E-01 «Fundaciones, documentación y plataforma de desarrollo»

**Épica:** E-01 · **Fase:** F0 — Cimientos
**Fecha de cierre:** 2026-11-17
**Autor:** Diego Alejandro Zamora Gallego
**Alcance:** T-001 … T-014 de `docs/03-tasks.md`, más T-100 (traslado de T-010/T-011)
**Estado:** E-01 cerrada en G2; validación de infraestructura trasladada a T-100

---

## 1. Resumen ejecutivo

| Estado | Tareas |
|---|---|
| Completadas y verificadas localmente | **11** — T-001, T-002, T-003, T-004, T-005, T-006, T-007, T-009, T-012, T-013, T-014 |
| Con evidencia parcial o bloqueo externo | **3** — T-008, T-010, T-011 |

Las tareas T-001…T-004 ya estaban cerradas antes de la ejecución de F0 y se revisaron sin cambios; el trabajo nuevo de
E-01 corresponde a T-005…T-014.

**E-01 se declara cerrada.** El 2026-11-17 el autor firmó **G1 y G2** (T-007) y resolvió **OQ-01…OQ-07**
(`01-spec.md` §12). Con esa puerta abierta se aplicó la enmienda de ADR-005, se re-planificaron T-160…T-165 y se
registró el cambio de alcance CC-02.

La única salvedad es de entorno, no de decisión: **T-010 y T-011 no pudieron validarse** porque esta máquina no tiene
Docker ni `gh`, y no existe repositorio remoto. Su validación se trasladó a **T-100**, primera tarea de F1, con
criterio de cierre explícito. No se afirma que Docker o el pipeline «funcionen»: solo que están escritos y revisados.

Lo que queda demostrado con evidencia ejecutada el 2026-11-14:

- Backend: **14 pruebas / 71 aserciones** en verde, **PHPStan nivel 8 sin errores**, Pint limpio,
  `composer audit` sin avisos.
- Móvil: **6 paquetes**, `flutter analyze` **sin ningún issue**, **25 pruebas** en verde vía Melos.
- Tiempo real: **40/40 eventos** entregados con **p50 17,808 ms / p95 18,820 ms** (loopback).
- Web: primera carga real de Flutter Web **2,32 MB**, por encima del presupuesto entonces vigente de 2 MB (RNF-06),
  con LCP/TTI no medibles → ADR-005. El embudo público pasa a Blade/Alpine con presupuesto ≤ 250 KB.

Desde el 2026-11-14 solo se modificó documentación; el código verificado no cambió.

---

## 2. Detalle por tarea

### T-005 — Monorepo y *scaffold* Laravel ✅

- `backend/` con Laravel **13.42.0** sobre **PHP 8.4.12** (`composer.json: php ^8.4`).
- `declare(strict_types=1)` forzado por Pint (`pint.json`, preset `psr12` + `strict_comparison`, `ordered_imports`,
  `no_unused_imports`).
- Larastan **3.15** nivel 8 (`phpstan.neon`, con extensión `pest-plugin-phpstan`).
- Pest **5.3** + PHPUnit 13; `tests/Pest.php` con `RefreshDatabase` para `Feature`.
- `Model::preventLazyLoading()` activo fuera de producción en `App\Providers\EloquentServiceProvider` (RNF-14).
- Scripts: `composer lint`, `lint:fix`, `analyse`, `security`, `test`, `quality`.
- **Desviación documentada:** PHP 8.4 en lugar de 8.3 porque Pest 5 exige `^8.4` (ADR-010).

### T-006 — Pruebas de arquitectura ✅

`backend/tests/Architecture/LayersTest.php` verifica:

- `Domain` no importa `Illuminate\*` ni `App\Infrastructure\*`.
- `Application` no importa `App\Http\*` ni `Illuminate\Http\*`.
- Los modelos Eloquent solo viven en `Infrastructure`.
- `Http` no contiene modelos Eloquent.

### T-007 — Aprobación G1 y G2 ✅

Aprobada el **2026-11-17** por Diego Alejandro Zamora Gallego. El acta queda en:

- `01-spec.md` §12 (resolución de OQ-01…OQ-07) y §14 (registro CC-01/CC-02).
- `02-plan.md` §14 (registro CC-01/CC-02).
- `00-constitucion.md` §11 (G1 y G2 «Aprobada 2026-11-17»).

Decisiones aceptadas: matriz de planes de §9 (OQ-01), una sede por tenant (OQ-02), SMS en F1 y WhatsApp en F3
(OQ-03), pasarela de pago decidida en ADR-008 antes de F3 (OQ-04), sin propinas ni descuentos (OQ-05), página liviana
para el embudo público (OQ-06) y solo efectivo esperado vs. contado (OQ-07).

### T-008 — *Spike* de tiempo real ⚠️ (medido en local)

| Elemento | Resultado |
|---|---|
| Servidor | Laravel Reverb 1.13 en `127.0.0.1:8080` |
| Cliente | `packages/fadespace_realtime/tool/latency_probe.dart` (protocolo Pusher sobre `web_socket_channel`) |
| Eventos | `App\Infrastructure\Realtime\RealtimeProbe` + `php artisan realtime:probe` |
| Muestra | 40 eventos, intervalo 200 ms |
| Resultado | **40/40 recibidos**, p50 **17,808 ms**, p95 **18,820 ms**, mín. 2,791 ms, máx. 31,773 ms |
| Evidencia | `spikes/t008/latency-40.json`, `spikes/t008/emit-40.log` |
| ADR | [ADR-004](../adr/ADR-004-realtime-client.md) |

Hallazgo operativo: con `REVERB_HOST=localhost` la latencia subió a ~221 ms porque Windows resolvía `::1`; con
`127.0.0.1` bajó a ~18 ms. Queda registrado en el ADR porque afecta a la configuración de despliegue.

**Pendiente:** validación en dispositivo real y bajo carga (T-206, T-207). El *spike* mide el camino de red, no el
requisito de producción con 1.000 conexiones.

### T-009 — *Spike* de peso y TTI de Flutter Web ✅ (medido en emulación, ADR-005 aplicado)

| Variante | Primera carga | Observación |
|---|---|---|
| dart2js + CanvasKit (por defecto) | **2,32 MB** reales en navegador | Supera el presupuesto de 2 MB (RNF-06) |
| wasm + skwasm (mejor caso, brotli 11) | **1,90 MB** estimados | Sin margen; exige COOP/COEP y navegadores modernos |

Métricas de la corrida Lighthouse (3G rápida simulada, CPU 4× más lenta): FCP **4,671 s**, Speed Index **12,696 s**,
CLS 0, y **LCP/TBT/TTI no calculables** (`LanternError: NO_LCP`) porque CanvasKit pinta sobre `<canvas>`.

Evidencia: `spikes/t009/size.json`, `spikes/t009/lighthouse-3g.json`, `spikes/t009/size-probe.cjs`,
`spikes/t009/static-server.cjs`. Decisión: [ADR-005](../adr/ADR-005-client-booking-frontend.md) — página liviana
server-rendered para el embudo público, **ratificada el 2026-11-14 y aplicada el 2026-11-17**. La medición de TTI de
la página Blade queda en T-164 (F1), con presupuesto ≤ 250 KB y TTI ≤ 3 s.

### T-010 — Docker Compose local ⚠️ (escrito, validación trasladada a T-100)

- `compose.yaml` con 6 servicios: `app` (PHP-FPM), `nginx`, `reverb`, `mysql:8.4`, `redis:7-alpine`, `mailpit`.
- *Healthchecks* de MySQL y Redis con `depends_on: condition: service_healthy`.
- Volúmenes nombrados para `vendor`, MySQL y Redis; red `fadespace`.
- Configuración de Reverb coherente con ADR-004: `REVERB_HOST=reverb` para el servidor y `VITE_REVERB_HOST=localhost`
  para el navegador.
- `infra/docker/php/Dockerfile` (PHP 8.4-FPM + extensiones), `infra/docker/php/php.ini`,
  `infra/docker/nginx/default.conf` (front controller + WebSocket *upgrade*), `.dockerignore`.

**Bloqueo externo:** no hay Docker instalado. `docker compose config` y `up` se ejecutan en **T-100** (F1).

### T-011 — Pipeline de CI y protección de ramas ⚠️ (escrito, primera ejecución en T-100)

- `.github/workflows/ci.yml` con 3 jobs: `backend` (Pint → Larastan → `composer audit` → Pest), `mobile`
  (formato → `flutter analyze` → Melos + `flutter test`) e `infra` (`docker compose config --quiet`).
- `infra/github/branch-protection.json` + `scripts/apply-branch-protection.ps1` (idempotente, verifica el resultado).
- `docs/ci.md` explica checks, equivalentes locales, aplicación y criterio de cierre.

**Bloqueo externo:** no existe repositorio GitHub ni `gh`. La creación del remoto, la primera ejecución y la
protección de rama se completan en **T-100** (F1).

### T-012 — *Scaffold* Flutter con Melos ✅

- Melos **8.10.1** + *pub workspaces* nativos (`mobile/pubspec.yaml` con `workspace:` y `resolution: workspace`).
- 6 paquetes: `apps/barber_app`, `apps/client_pwa`, `packages/{fadespace_core, fadespace_api, fadespace_realtime,
  fadespace_ui}`.
- `very_good_analysis` **11.0.0** en todos; `analysis_options.yaml` raíz con exclusiones justificadas.
- l10n `es` + `es_CO` con `flutter gen-l10n` en ambas apps (`lib/l10n/generated/`).
- Navegación real: `barber_app` con `StatefulShellRoute` (Agenda, Modo Silla, Ganancias, Ajustes); `client_pwa` con
  reserva → confirmación → Mi cita (cáscara experimental tras ADR-005).
- **Pruebas:** `fadespace_core` (Money), `fadespace_api` (tenant, versión, token, idempotencia), `fadespace_realtime`
  (suscripción y decodificación), `fadespace_ui` (widgets y 360 px con texto 1,3×), `barber_app` (2), `client_pwa` (2).
- **Desviación documentada:** Flutter 3.50 deprecó `package:flutter/material.dart`; se migró a `material_ui` /
  `cupertino_ui` (ADR-010).

### T-013 — ADR-001, 002, 003, 006 y 007 ✅

`docs/adr/` contiene ADR-001, 002, 003, 004 (spike T-008), 005 (spike T-009), 006, 007 y ADR-010 (línea base de
toolchain, exigido por C-17 por las dependencias nuevas), más el índice con estados y pendientes. ADR-005 y ADR-006
quedaron en estado **Aceptado** al cerrar G2.

### T-014 — Observabilidad base ✅

- `RequestContext` (singleton *scoped*) con `request_id` (UUID v7 cuando el cliente no envía `X-Request-Id`) y
  `tenant_id`.
- `AssignRequestContext` (middleware global) + propagación de `X-Request-Id` en la respuesta.
- Logging JSON: canal `stack` con `JsonFormatter`, tap `ConfigureStructuredLogging`, procesadores
  `RequestContextProcessor` y `MaskSensitiveData` (teléfonos → `***1234`, correos, tokens).
- `HealthChecker` + `GET /api/v1/health` con estado de base de datos y caché.
- 6 pruebas dedicadas (`HealthEndpointTest`, `RequestContextTest`, `StructuredLogTest`,
  `MaskSensitiveDataTest`, `RequestContextProcessorTest`).

---

## 3. Verificación ejecutada

Ejecutada el **2026-11-14**; no se repitió el 2026-11-17 porque el cierre solo modificó documentación.

### Backend

```
composer lint      → pint: passed
composer analyse   → phpstan: passed, errors: 0 (nivel 8)
composer security  → No security vulnerability advisories found.
composer test      → pest: passed, tests: 14, assertions: 71
```

### Móvil

```
dart format --output=none --set-exit-if-changed .   → 0 cambios
flutter analyze                                     → No issues found! (6 paquetes)
melos exec --dir-exists=test -- flutter test         → SUCCESS (6 paquetes, 25 pruebas)
flutter build web --release                         → √ Built build\web   (client_pwa)
flutter build web --release --wasm                  → √ Built build\web_wasm
```

### Reproducibilidad de los *spikes*

```powershell
# T-008
php artisan reverb:start --host=127.0.0.1 --port=8080 --debug
$env:REVERB_HOST="127.0.0.1"; php artisan realtime:probe --count=40 --interval=200
cd mobile/packages/fadespace_realtime
dart run tool/latency_probe.dart --duration=25 --url=ws://127.0.0.1:8080 `
  --key=fadespace-local-key --output=../../../spikes/t008/latency-40.json

# T-009
flutter build web --release --wasm --no-wasm-dry-run -o build\web_wasm
node spikes/t009/static-server.cjs mobile/apps/client_pwa/build/web 8099
npx lighthouse@12 http://127.0.0.1:8099/ --form-factor=mobile --throttling-method=simulate `
  --throttling.rttMs=150 --throttling.throughputKbps=1600 --throttling.cpuSlowdownMultiplier=4 `
  --only-categories=performance --output=json --output-path=./spikes/t009/lighthouse-3g.json
```

---

## 4. Bloqueos y evidencias parciales

| Tarea | Estado | Qué falta | Dónde se cierra |
|---|---|---|---|
| T-010 | Bloqueo externo | `docker compose config/up` y migraciones | T-100 (F1) |
| T-011 | Bloqueo externo | Repositorio remoto, pipeline y protección de rama | T-100 (F1) |
| T-008 | Evidencia parcial | Dispositivo real y 1.000 conexiones | T-206/T-207 (F2) |
| T-009 | Cerrada | TTI y peso de la página Blade/Alpine | T-164 (F1) |
| ADR-005 | Aplicado | — | — |

T-100 es la primera tarea de F1: exige Docker Desktop, un repositorio GitHub y `gh auth`, ninguno disponible en F0.

---

## 5. Decisiones aprobadas en G1/G2

### 5.1 Preguntas abiertas (OQ) — resueltas el 2026-11-17

| ID | Decisión aprobada | Consecuencia |
|---|---|---|
| OQ-01 | Matriz de planes de `01-spec.md` §9 como línea base de v1.0 | `PlanGate` y precios quedan fijados; cambios vía CC y T-330 |
| OQ-02 | **Una sede por tenant** en v1.0 | El modelo no necesita tabla de sedes; multi-sucursal en backlog |
| OQ-03 | SMS en F1 detrás de `OtpChannel`, WhatsApp en F3 (ADR-006) | Habilita T-137/T-138 sin esperar plantillas de Meta |
| OQ-04 | Pasarela decidida en ADR-008 antes de F3 | No bloquea F1; Wompi/Stripe se evalúan en T-331 |
| OQ-05 | Sin propinas ni descuentos en v1.0 | `transactions` no necesita campos de propina/descuento |
| OQ-06 | Página liviana server-rendered (ADR-005) | T-160…T-165 re-planificadas; `client_pwa` experimental |
| OQ-07 | Solo efectivo esperado vs. contado; retiros en backlog | `cash_closings` no modela retiros |

### 5.2 ADR-005 — aplicado

ADR-005 es la única decisión que **contradecía** `02-plan.md` §1 (PWA del cliente en Flutter Web). Se tomó porque la
evidencia medida es concluyente (2,32 MB > 2 MB y TTI no medible) y porque C-13 exige *assets* livianos para 3G.

**Aplicación del 2026-11-17** (control de cambios CC-02):

1. `02-plan.md` §1, §4, §7, §9, §10, §11 y §12 enmendados: el embudo público es Blade/Alpine y `client_pwa` queda
   experimental.
2. T-160…T-165 re-planificadas a Blade/Alpine + Playwright, con presupuesto ≤ 250 KB y TTI ≤ 3 s (T-164).
3. `01-spec.md` §12 marca OQ-06 como resuelta y §14 registra CC-02.
4. `04-traceability.md` actualiza RNF-06, los módulos de RF-08/RF-10/RF-13 y el estado de E-01.

Si en el futuro se quisiera volver a Flutter Web, haría falta un ADR que reemplace a ADR-005 y una enmienda a RNF-06.

---

## 6. Riesgos abiertos tras E-01

| Riesgo | Nivel | Mitigación actual | Próximo paso |
|---|---|---|---|
| `compose.yaml` no ejecutado nunca | Medio | Revisión manual de servicios, *healthchecks*, volúmenes y variables | T-100 antes de E-02 |
| CI nunca ejecutado en GitHub | Medio | Workflow escrito y comandos equivalentes verdes en local | T-100: remoto, ejecución y protección |
| TTI real de la página de reserva desconocido | Medio | Presupuesto ≤ 250 KB y ADR-005 | Lighthouse CI y WebPageTest en T-164 |
| Latencia WS medida solo en loopback | Medio | Cliente con reconexión y plan de monitor sintético | T-206/T-207 en F2 |
| PHP 8.4 en producción | Bajo | ADR-010 y `Dockerfile` con `php:8.4-fpm` | Alinear *staging* y CI en T-100/T-170 |

---

## 7. Próximo paso recomendado

1. **T-100 (precondición de F1):** con Docker Desktop y GitHub disponibles, validar `compose.yaml`
   (`config`, `up -d --build`, `migrate --seed`), publicar el repositorio, ejecutar el pipeline y aplicar
   `scripts/apply-branch-protection.ps1`.
2. **E-02 (T-101):** iniciar F1 con el modelo de datos de la spec y el aislamiento multi-tenant de ADR-001.
3. **T-160…T-165:** construir la página de reserva Blade/Alpine con el presupuesto de ADR-005; `client_pwa` no se
   despliega.

---

## 8. Inventario de archivos creados o modificados en E-01

```
backend/                                  Scaffold Laravel 13 + calidad + observabilidad
  app/Domain/Shared/DomainException.php
  app/Application/Shared/TransactionManager.php
  app/Infrastructure/Observability/**      RequestContext, logging JSON, masking, health
  app/Infrastructure/Persistence/Eloquent/ Models/User.php, EloquentServiceProvider
  app/Infrastructure/Realtime/RealtimeProbe.php
  app/Console/Commands/RealtimeProbeCommand.php
  app/Http/Middleware/AssignRequestContext.php
  app/Http/Controllers/Api/V1/HealthController.php
  tests/Architecture/LayersTest.php
  tests/Feature/Observability/** · tests/Unit/**
  composer.json · phpstan.neon · pint.json · phpunit.xml
mobile/                                    Monorepo Flutter (Melos + workspaces)
  pubspec.yaml · analysis_options.yaml
  apps/barber_app/**                        Agenda, Modo Silla, Ganancias, Ajustes + l10n
  apps/client_pwa/**                        Cáscara experimental (reserva, confirmación, Mi cita)
  packages/fadespace_core/**                Money, Result, Failure
  packages/fadespace_api/**                 Cliente dio, tenant, idempotencia
  packages/fadespace_realtime/**            Cliente Pusher/Reverb + latency_probe.dart
  packages/fadespace_ui/**                  Tema, PrimaryActionButton, StatusPill
infra/
  docker/php/{Dockerfile,php.ini} · docker/nginx/default.conf
  github/branch-protection.json
docs/
  adr/README.md · ADR-001,002,003,004,005,006,007,010
  ci.md · status/E-01-report.md
  (actualizados el 2026-11-17) 00-constitucion.md · 01-spec.md · 02-plan.md
  03-tasks.md · 04-traceability.md
spikes/
  t008/{latency-40.json,emit-40.log}
  t009/{size.json,lighthouse-3g.json,size-probe.cjs,static-server.cjs}
.github/workflows/ci.yml
compose.yaml · .dockerignore · .gitignore · README.md
scripts/apply-branch-protection.ps1
```

---

## 9. Control de cambios del informe

| Versión | Fecha | Cambio |
|---|---|---|
| 1.0 | 2026-11-14 | Informe inicial de cierre de E-01 con los pendientes explícitos. |
| 1.1 | 2026-11-14 | **ADR-005 ratificado** por el autor (OQ-06 resuelta): T-009 pasa a completada y el riesgo asociado baja a Medio. Se inicializa el repositorio Git local (`main`, primer *commit* sin remoto). |
| 1.2 | 2026-11-17 | **E-01 cerrada:** G1/G2 firmadas (T-007) y OQ-01…OQ-07 resueltas. Se aplica ADR-005 (enmienda de `02-plan.md` y re-planificación de T-160…T-165), se registra CC-01/CC-02 y se traslada la validación de T-010/T-011 a T-100. ADR-006 pasa a Aceptado. |
