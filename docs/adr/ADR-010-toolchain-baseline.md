# ADR-010 — Línea base de toolchain del monorepo

- **Estado:** Aceptado
- **Fecha:** 2026-11-14
- **Requisitos:** C-08, C-13, C-17, RNF-13, RNF-16
- **Tareas:** T-005, T-011, T-012, T-014

## Contexto

`00-constitucion.md` fija mínimos (PHP ≥ 8.3, PSR-12, Larastan nivel 8, Pest, `flutter analyze` limpio) pero no
fija versiones. C-17 exige un ADR por cada dependencia nueva y decisión estructural. En F0 se instaló el *scaffold*
completo, y conviene dejar registrado **qué** se instaló, **por qué** y **dónde** se desvía del texto de la
constitución.

No existía ADR para esta decisión en la tabla de `02-plan.md` §10 (que llega a ADR-009), de ahí que se numere como
**ADR-010**.

## Decisión

### Backend (`backend/`)

| Componente | Versión fijada | Motivo |
|---|---|---|
| PHP | **8.4.12** (`^8.4` en `composer.json`) | La constitución pide ≥ 8.3; Pest 5 exige `^8.4`, así que el mínimo real sube. El contenedor de `infra/docker/php` debe usar 8.4. |
| Laravel | **13.42.0** (`^13.17`) | Framework base; Reverb y Sanctum ya son paquetes de primera parte. |
| Laravel Reverb | `^1.13` | Servidor WebSocket Pusher-compatible exigido por ADR-004. |
| Pest | **5.3** + `pest-plugin-laravel` 5 | Suite de pruebas y pruebas de arquitectura (T-006). |
| Larastan | **3.15** (nivel 8) | Exigido por RNF-13 y por la constitución §3. |
| Pint | **1.27** (`preset: psr12`) | Formato PSR-12 en CI; reglas añadidas: `declare_strict_types`, `strict_comparison`, `ordered_imports`, `no_unused_imports`. |
| predis/predis | `^3.7` | Cliente Redis en PHP puro: funciona sin la extensión `phpredis` y simplifica el entorno local y el CI. |
| PHPUnit | 13 | Motor bajo Pest (Pest 5 lo requiere). |

**Configuración relevante ya en el repositorio:** `phpstan.neon` incluye Larastan y `pest-plugin-phpstan`;
`pint.json` fuerza `declare(strict_types=1)`; `composer quality` encadena `lint` + `analyse` + `security`
(`composer audit`) + `test`; `Model::preventLazyLoading()` se activa fuera de producción en `EloquentServiceProvider`
(RNF-14).

### Móvil (`mobile/`)

| Componente | Versión fijada | Motivo |
|---|---|---|
| Flutter | **3.50** (canal estable), Dart `^3.14` | SDK instalado y validado en F0. |
| Melos | **8.10.1** (`dev_dependencies`) | Scripts de monorepo (`melos exec`, `melos list`). Requiere declararse en el `pubspec.yaml` raíz para resolver el *workspace*. |
| *Pub workspaces* | `workspace:` + `resolution: workspace` | Resolución única de dependencias para los 6 paquetes (sin `pub get` por paquete). |
| very_good_analysis | **11.0.0** | Reglas de análisis estrictas; `include: package:very_good_analysis/analysis_options.yaml` (el archivo `very_good_analysis.yaml` no existe en v11). |
| flutter_riverpod | **3.5.0** | ADR-007. |
| go_router | **18.1.4** | ADR-007 (`StatefulShellRoute`). |
| dio | **5.11.1** | Cliente HTTP con interceptores para tenant, versión y `Idempotency-Key`. |
| web_socket_channel | **3.0.3** | ADR-004. |
| intl | **0.20.3** | Formato de moneda/fecha `es-CO`; alineado con `flutter_localizations`. |
| material_ui / cupertino_ui | **1.11.0** / **1.1.6** | Ver desviación 2. |

### Desviaciones explícitas respecto a los documentos

1. **PHP 8.4 en lugar de 8.3.** Pest 5 + Laravel 13 requieren 8.4. La constitución dice "≥ 8.3", por lo que se
   cumple; el efecto práctico es que **staging y producción deben usar PHP 8.4** y que el `Dockerfile` fija
   `php:8.4-fpm`.
2. **`package:material_ui` + `package:cupertino_ui` en vez de `package:flutter/material.dart`.** Flutter 3.50
   deprecó `package:flutter/material.dart` a favor de los paquetes externos `material_ui`/`cupertino_ui`. Se migró
   todo el código (apps y `fadespace_ui`) y se añadieron los *delegates* `GlobalMaterialLocalizations` y
   `GlobalCupertinoLocalizations` desde esos paquetes, más `GlobalWidgetsLocalizations` desde
   `flutter_localizations`. Sin esta migración `flutter analyze` queda con `deprecated_member_use` en todos los
   imports de UI.
3. **`predis` en lugar de la extensión `phpredis`.** Menos requisitos de compilación; el rendimiento es suficiente
   para *holds*, OTP y caché (D-04) y se revisará si las pruebas de carga de F2 lo exigen.
4. **Melos declarado como `dev_dependency` del *workspace*.** Sin esa entrada, Melos 8 responde "Your current
   directory does not appear to be within a Melos workspace" aunque exista la sección `melos:` en el `pubspec.yaml`
   raíz (comportamiento verificado en este entorno).
5. **`meta` explícito en `fadespace_core`.** Necesario para `@immutable` en `Money` (regla
   `avoid_equals_and_hash_code_on_mutable_classes` de VGA 11).

## Alternativas descartadas

| Alternativa | Por qué no |
|---|---|
| PHP 8.3 + Pest 4 | Funciona, pero deja el proyecto un *major* por detrás en el motor de pruebas y obliga a migrar la suite en F1. |
| PHPUnit puro sin Pest | Pierde pruebas de arquitectura declarativas (`arch()`) y la sintaxis de expectativas que usa la spec. |
| `phpstan` solo (sin Larastan) | No entiende las *magic properties* de Eloquent; nivel 8 sería inalcanzable en `Infrastructure`. |
| Sin Melos, solo *workspaces* nativos | Los *workspaces* resuelven dependencias, pero no hay comandos agregados (`melos exec`) para CI. |
| Mantener `package:flutter/material.dart` | Genera advertencias de deprecación en cada archivo y romperá en la siguiente versión estable. |
| `http` en lugar de `dio` | `dio` ofrece interceptores, que es la forma limpia de aplicar tenant, `X-Client-Version` e `Idempotency-Key` en un solo lugar. |

## Consecuencias

**Positivas**

- Versiones fijadas y reproducibles: `composer.lock` y `pubspec.lock` versionados, CI con las mismas versiones.
- El *scaffold* pasa `composer quality` (Pint, Larastan 8, audit, 14 pruebas) y `flutter analyze` sin *issues* en
  los 6 paquetes.
- La migración a `material_ui` deja el proyecto listo para futuras versiones de Flutter.

**Negativas y mitigaciones**

- PHP 8.4 obliga a actualizar la imagen de despliegue y la máquina de desarrollo → documentado en el `Dockerfile`
  y en el README de backend.
- `material_ui`/`cupertino_ui` son paquetes jóvenes → versiones fijadas en `pubspec.lock` y análisis en CI para
  detectar roturas temprano.
- Dependencia de la versión exacta de Flutter (3.50) → el workflow de CI fija `flutter-version: '3.50.0'`.

## Verificación

- `composer quality` en verde (Pint, Larastan nivel 8, `composer audit`, Pest).
- `flutter analyze` (`No issues found!`) y `melos exec --dir-exists=test -- flutter test` en verde.
- CI (`.github/workflows/ci.yml`) reproduce ambos conjuntos en Ubuntu con PHP 8.4 y Flutter 3.50.
- `backend/phpstan.neon`, `backend/pint.json`, `mobile/analysis_options.yaml`, `mobile/pubspec.yaml`.

## Referencias

- `docs/00-constitucion.md` §3 y §5, C-08, C-17.
- `docs/02-plan.md` §10 (tabla de ADR), §11 riesgos.
- `backend/composer.json`, `mobile/pubspec.yaml`, `.github/workflows/ci.yml`.
