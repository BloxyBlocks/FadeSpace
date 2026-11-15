# Informe de cierre — E-01 «Fundaciones, documentación y plataforma de desarrollo»

**Épica:** E-01 · **Fase:** F0 — Cimientos
**Fecha:** 2026-11-14
**Autor:** Diego Alejandro Zamora Gallego
**Alcance:** T-001 … T-014 de `docs/03-tasks.md`

---

## 1. Resumen ejecutivo

| Estado | Tareas |
|---|---|
| Completadas y verificadas localmente | **10** — T-001, T-002, T-003, T-004, T-005, T-006, T-009, T-012, T-013, T-014 |
| En curso con evidencia parcial | **3** — T-008, T-010, T-011 |
| Bloqueada por revisión humana | **1** — T-007 (G1/G2) |

Las tareas T-001…T-004 ya estaban cerradas antes de esta ejecución y se revisaron sin cambios; el trabajo nuevo de
E-01 corresponde a T-005…T-014.

**F0 no se declara cerrada.** El criterio de salida exige G1 y G2 aprobadas, ambos *spikes* resueltos con ADR y CI
en verde. Los *spikes* tienen ADR y evidencia reproducible, pero **G1/G2 son una puerta humana** y la validación
real de Docker y del pipeline remoto no es posible en este entorno (Docker no instalado, sin repositorio GitHub).

Lo que sí queda demostrado con evidencia ejecutada:

- Backend: **14 pruebas / 71 aserciones** en verde, **PHPStan nivel 8 sin errores**, Pint limpio,
  `composer audit` sin avisos.
- Móvil: **6 paquetes**, `flutter analyze` **sin ningún issue**, **25 pruebas** en verde vía Melos.
- Tiempo real: **40/40 eventos** entregados con **p50 17,808 ms / p95 18,820 ms** (loopback).
- Web: primera carga real de Flutter Web **2,32 MB**, por encima del presupuesto de 2 MB (RNF-06), con LCP/TTI no
  medibles → ADR-005.

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

### T-007 — Aprobación G1 y G2 ⛔

No ejecutable por un agente. Requiere revisión humana de `00-constitucion.md`, `01-spec.md` y `02-plan.md`, y una
decisión explícita sobre **OQ-01…OQ-07** (§5 de este informe). Sin esta puerta, F1 no debe comenzar (C-16).

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

### T-009 — *Spike* de peso y TTI de Flutter Web ✅ (medido en emulación, decisión ratificada)

| Variante | Primera carga | Observación |
|---|---|---|
| dart2js + CanvasKit (por defecto) | **2,32 MB** reales en navegador | Supera el presupuesto de 2 MB (RNF-06) |
| wasm + skwasm (mejor caso, brotli 11) | **1,90 MB** estimados | Sin margen; exige COOP/COEP y navegadores modernos |

Métricas de la corrida Lighthouse (3G rápida simulada, CPU 4× más lenta): FCP **4,671 s**, Speed Index **12,696 s**,
CLS 0, y **LCP/TBT/TTI no calculables** (`LanternError: NO_LCP`) porque CanvasKit pinta sobre `<canvas>`.

Evidencia: `spikes/t009/size.json`, `spikes/t009/lighthouse-3g.json`, `spikes/t009/size-probe.cjs`,
`spikes/t009/static-server.cjs`. Decisión: [ADR-005](../adr/ADR-005-client-booking-frontend.md) — página liviana
server-rendered para el embudo público, **ratificada el 2026-11-14**. La medición de TTI en dispositivo real queda
en T-164 (F1), junto con la re-planificación de T-160…T-165 al cerrar G2.

### T-010 — Docker Compose local ⚠️ (escrito, no ejecutado)

- `compose.yaml` con 6 servicios: `app` (PHP-FPM), `nginx`, `reverb`, `mysql:8.4`, `redis:7-alpine`, `mailpit`.
- *Healthchecks* de MySQL y Redis con `depends_on: condition: service_healthy`.
- Volúmenes nombrados para `vendor`, MySQL y Redis; red `fadespace`.
- Configuración de Reverb coherente con ADR-004: `REVERB_HOST=reverb` para el servidor y `VITE_REVERB_HOST=localhost`
  para el navegador.
- `infra/docker/php/Dockerfile` (PHP 8.4-FPM + extensiones), `infra/docker/php/php.ini`,
  `infra/docker/nginx/default.conf` (front controller + WebSocket *upgrade*), `.dockerignore`.

**Pendiente:** `docker compose config` y `up` en una máquina con Docker. No hay Docker instalado en el entorno de
F0, por lo que ninguna afirmación de «funciona» sería verificable.

### T-011 — Pipeline de CI y protección de ramas ⚠️ (escrito, no ejecutado en remoto)

- `.github/workflows/ci.yml` con 3 jobs: `backend` (Pint → Larastan → `composer audit` → Pest), `mobile`
  (formato → `flutter analyze` → Melos + `flutter test`) e `infra` (`docker compose config --quiet`).
- `infra/github/branch-protection.json` + `scripts/apply-branch-protection.ps1` (idempotente, verifica el resultado).
- `docs/ci.md` explica checks, equivalentes locales, aplicación y criterio de cierre.

**Pendiente:** crear el repositorio remoto, ejecutar el pipeline y aplicar la protección con permisos de
administrador.

### T-012 — *Scaffold* Flutter con Melos ✅

- Melos **8.10.1** + *pub workspaces* nativos (`mobile/pubspec.yaml` con `workspace:` y `resolution: workspace`).
- 6 paquetes: `apps/barber_app`, `apps/client_pwa`, `packages/{fadespace_core, fadespace_api, fadespace_realtime,
  fadespace_ui}`.
- `very_good_analysis` **11.0.0** en todos; `analysis_options.yaml` raíz con exclusiones justificadas.
- l10n `es` + `es_CO` con `flutter gen-l10n` en ambas apps (`lib/l10n/generated/`).
- Navegación real: `barber_app` con `StatefulShellRoute` (Agenda, Modo Silla, Ganancias, Ajustes); `client_pwa` con
  reserva → confirmación → Mi cita.
- **Pruebas:** `fadespace_core` (Money), `fadespace_api` (tenant, versión, token, idempotencia), `fadespace_realtime`
  (suscripción y decodificación), `fadespace_ui` (widgets y 360 px con texto 1,3×), `barber_app` (2), `client_pwa` (2).
- **Desviación documentada:** Flutter 3.50 deprecó `package:flutter/material.dart`; se migró a `material_ui` /
  `cupertino_ui` (ADR-010).

### T-013 — ADR-001, 002, 003, 006 y 007 ✅

`docs/adr/` contiene ADR-001, 002, 003, 004 (spike T-008), 005 (spike T-009), 006, 007 y ADR-010 (línea base de
toolchain, exigido por C-17 por las dependencias nuevas), más el índice con estados y pendientes.

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

## 4. Bloqueos, con causa y responsable

| Tarea | Bloqueo | Causa | Quién lo desbloquea |
|---|---|---|---|
| T-007 | G1/G2 sin aprobar | Puerta humana obligatoria (C-16) | Autor / negocio |
| T-010 | Sin validación de Docker | Docker no está instalado en el entorno | Quien tenga Docker Desktop |
| T-011 | Sin CI remoto | No existe repositorio GitHub ni credenciales | Autor (crear remoto y `gh auth`) |
| T-008 | Sin dispositivo real ni carga | Solo hay entorno local | F2 (T-206/T-207) |
| T-009 | Sin TTI real | No hay dispositivo de gama media ni red real | F1 (T-164) con WebPageTest |
| ADR-005 | Enmienda de plan | Cambia el cliente web de `02-plan.md` §5 | G2 (T-007) |

---

## 5. Decisiones que requieren aprobación humana

### 5.1 Preguntas abiertas (OQ)

| ID | Propuesta para aceptar en G1/G2 | Consecuencia si se acepta |
|---|---|---|
| OQ-01 | Usar la matriz de planes de `01-spec.md` §9 y validarla con negocio | `PlanGate` y precios quedan fijados para F1/F3 |
| OQ-02 | **Una sede por tenant** en v1.0 | El modelo de datos no necesita tabla de sedes; el add-on queda en backlog |
| OQ-03 | SMS en F1 detrás de `OtpChannel`, WhatsApp en F3 (ADR-006) | Habilita T-137/T-138 sin esperar plantillas de Meta |
| OQ-04 | Decidir pasarela antes de F3 (ADR-008) | No bloquea F1; Wompi/Stripe se evalúan en su momento |
| OQ-05 | Sin propinas ni descuentos en v1.0 | `transactions` no necesita campos de propina/descuento |
| OQ-06 | **Resuelto:** Flutter Web no cumple el presupuesto; página liviana server-rendered (ADR-005 ratificado el 2026-11-14) | Re-planificar T-160…T-165 al cerrar G2 |
| OQ-07 | Solo efectivo esperado vs. contado; retiros en backlog | `cash_closings` no modela retiros |

### 5.2 ADR-005 — ratificado

ADR-005 es la única decisión que **contradice** `02-plan.md` (§5 define PWA del cliente en Flutter Web). Se tomó
porque la evidencia medida es concluyente (2,32 MB > 2 MB y TTI no medible) y porque C-13 exige *assets* livianos
para 3G.

**Ratificación:** el 2026-11-14 el autor aprobó la página liviana para el embudo público. Queda por ejecutar, al
cerrar G2:

1. Enmendar `02-plan.md` §5/§7 (cliente web de reserva).
2. Re-planificar T-160…T-165 (Blade/Alpine + Playwright en lugar de *scaffold* Flutter).
3. Reflejar OQ-06 como resuelta en `01-spec.md` §12.

Si en el futuro se quisiera volver a Flutter Web, haría falta un ADR que reemplace a ADR-005 y una enmienda a
RNF-06.

---

## 6. Riesgos abiertos tras E-01

| Riesgo | Nivel | Mitigación actual | Próximo paso |
|---|---|---|---|
| `compose.yaml` no ejecutado nunca | Alto | Revisión manual de servicios, *healthchecks*, volúmenes y variables | Validar en Docker Desktop antes de F1 |
| CI nunca ejecutado en GitHub | Medio | Workflow escrito y comandos equivalentes verdes en local | Crear remoto, ejecutar, aplicar protección |
| ADR-005 ratificado, enmienda pendiente | Medio | Decisión ratificada el 2026-11-14 y evidencia en `spikes/t009/` | Re-planificar T-160…T-165 y enmendar `02-plan.md` §5/§7 al cerrar G2 |
| TTI real desconocido | Medio | Medición simulada y análisis de causa | WebPageTest + dispositivo real en T-164 |
| Latencia WS medida solo en loopback | Medio | Cliente con reconexión y plan de monitor sintético | T-206/T-207 en F2 |
| PHP 8.4 en producción | Bajo | ADR-010 y `Dockerfile` con `php:8.4-fpm` | Alinear *staging* y CI |
| Historial sin remoto | Bajo | Repositorio Git local inicializado (`main`, primer *commit*) | Crear remoto y publicar |

---

## 7. Próximo paso recomendado

1. **Humano:** revisar este informe, resolver OQ-01…OQ-05 y OQ-07, y firmar G1/G2 (T-007). OQ-06 ya está resuelta y
   ADR-005 ratificado, pero la enmienda de `02-plan.md` §5/§7 y la re-planificación de T-160…T-165 se ejecutan en
   esa misma puerta.
2. **Humano:** crear el repositorio remoto en GitHub, publicar (`git remote add origin … && git push -u origin main`)
   y ejecutar el pipeline; después aplicar la protección con `scripts/apply-branch-protection.ps1` (T-011).
3. **Con Docker disponible:** `docker compose up -d --build` + `php artisan migrate --seed` para cerrar T-010.
4. **F1:** tras G2, iniciar E-02 (T-101) con el modelo de datos de la spec y el aislamiento multi-tenant de ADR-001.

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
  apps/client_pwa/**                        Reserva, confirmación, Mi cita + l10n
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
  (actualizados) 03-tasks.md · 04-traceability.md
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
