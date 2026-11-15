# FadeSpace

Monorepo de FadeSpace: API y dashboard (Laravel), app del barbero y PWA del cliente (Flutter), más la
documentación de especificación, plan, tareas y decisiones de arquitectura.

> **Estado:** F0 — cimientos. La puerta **G1/G2** (revisión humana de constitución, spec y plan) está pendiente; ver
> [`docs/03-tasks.md`](docs/03-tasks.md) (T-007).

## Estructura

```
backend/                 Laravel 13 (API /api/v1, Livewire, Reverb)
  app/{Domain,Application,Infrastructure,Http}
  tests/{Architecture,Feature,Unit}
infra/docker/            Dockerfile PHP-FPM, php.ini, Nginx
mobile/                  Monorepo Flutter (Melos + pub workspaces)
  apps/barber_app        App del barbero (Modo Silla)
  apps/client_pwa        Cáscara Flutter Web (experimento, ver ADR-005)
  packages/              fadespace_core · fadespace_api · fadespace_realtime · fadespace_ui
docs/                    Constitución, spec, plan, tareas, trazabilidad y ADR
spikes/                  Evidencia reproducible de los spikes T-008 y T-009
.github/workflows/ci.yml Pipeline de integración continua
compose.yaml             Stack local (PHP-FPM, Nginx, MySQL 8, Redis 7, Mailpit, Reverb)
```

## Requisitos

| Herramienta | Versión | Nota |
|---|---|---|
| PHP | 8.4 | `composer.json` exige `^8.4` (Pest 5). |
| Composer | 2.x | |
| Node.js | 20+ | Solo para *assets* del backend y herramientas de medición. |
| Flutter | 3.50 (Dart 3.14) | |
| Docker + Docker Compose | opcional | Necesario para `compose.yaml`. |

## Backend

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
composer quality        # Pint --test + Larastan 8 + composer audit + Pest
```

Servicios: `composer dev` levanta API, colas, logs y Vite. Endpoint de salud: `GET /api/v1/health`.

## Móvil

```bash
cd mobile
flutter pub get                      # resuelve todo el workspace
dart pub global activate melos 8.10.1
melos list                           # 6 paquetes
melos exec --dir-exists=test -- flutter test
flutter analyze
```

Generación de textos (`es` / `es_CO`): `cd mobile/apps/barber_app && flutter gen-l10n` (ídem `client_pwa`).

## Stack local con Docker

```bash
docker compose up -d --build
docker compose exec app php artisan migrate --seed
```

- API: <http://localhost:8000>
- Mailpit: <http://localhost:8025>
- Reverb (WebSocket): `ws://localhost:8080`

## Documentación

| Documento | Contenido |
|---|---|
| [`docs/00-constitucion.md`](docs/00-constitucion.md) | Principios no negociables, reglas de capas y puertas de aprobación. |
| [`docs/01-spec.md`](docs/01-spec.md) | Requisitos funcionales, no funcionales, modelo de datos y escenarios. |
| [`docs/02-plan.md`](docs/02-plan.md) | Arquitectura, fases, riesgos y tabla de ADR. |
| [`docs/03-tasks.md`](docs/03-tasks.md) | Tareas por épica y fase con criterios de salida. |
| [`docs/04-traceability.md`](docs/04-traceability.md) | Matriz requisito → módulo → prueba → estado. |
| [`docs/adr/`](docs/adr/README.md) | Decisiones de arquitectura y su evidencia. |
| [`docs/ci.md`](docs/ci.md) | Pipeline, calidad obligatoria y protección de ramas. |
| [`docs/status/E-01-report.md`](docs/status/E-01-report.md) | Informe de cierre de E-01 con lo verificado y lo pendiente. |

## Licencia

Propietario — Bloxysoft. Todos los derechos reservados.
