# Constitución del proyecto — FadeSpace

**Versión:** 1.0  
**Estado:** Aprobada en G1/G2 el 2026-11-17  
**Autor:** Diego Alejandro Zamora Gallego  
**Iniciativa:** Bloxysoft  
**Versión de la app:** 1.0  
**Método:** SEDD / Spec-Driven Development

---

## 1. Propósito

Este documento define los principios no negociables que gobiernan el diseño, la implementación y la evolución de **FadeSpace**: una plataforma SaaS *multi-tenant* de gestión operativa, agendamiento y cobros para barberías, construida con **Laravel, MySQL, Redis, Laravel Reverb y Flutter**.

Toda spec, plan, tarea y línea de código debe ser coherente con esta constitución. Si existe conflicto, **prevalece la constitución**.

---

## 2. Principios no negociables

| ID | Principio | Regla |
|---|---|---|
| **C-01** | **La especificación manda** | Ningún cambio de comportamiento se implementa sin actualizar `01-spec.md` (requisitos, reglas de negocio y criterios Gherkin). |
| **C-02** | **Trazabilidad total** | Cada `RF-xx`, `RNF-xx` y `C-xx` se vincula a un módulo, una tarea y una prueba en `04-traceability.md`. Nada se cierra en G4 sin esa cadena completa. |
| **C-03** | **Aislamiento multi-tenant inviolable** | Un tenant jamás puede leer, escribir, escuchar ni inferir datos de otro tenant (base de datos, caché, colas, WebSockets, archivos y logs). Ver §5. |
| **C-04** | **Integridad transaccional e idempotencia** | Toda mutación de negocio es atómica: validar → aplicar → persistir → auditar → emitir eventos (después del *commit*). Los endpoints críticos aceptan `Idempotency-Key`. |
| **C-05** | **Cero overbooking** | Una franja nunca se asigna dos veces. Se exige la combinación *Cache Hold* (Redis, 180 s) + *Pessimistic Locking* (`SELECT … FOR UPDATE`) en MySQL. Ninguna de las dos capas sustituye a la otra. |
| **C-06** | **Dinero exacto e inmutable** | Prohibido `float` para importes. Se usan `DECIMAL(10,2)` y un *value object* `Money`. Las transacciones no se editan ni se borran: se corrigen con un reverso. `total = barber_amount + shop_amount` siempre. |
| **C-07** | **Clean Architecture y separación de responsabilidades** | Dominio puro → Aplicación (casos de uso) → Infraestructura → Interfaces (HTTP/Livewire/Flutter). La dependencia apunta siempre hacia adentro. Ver §4. |
| **C-08** | **Estándares de código** | PHP: PSR-12, `declare(strict_types=1)`, análisis estático sin errores. Flutter: `analyze` sin advertencias, formateo automático. Ver §3 y §7. |
| **C-09** | **Tiempo real < 200 ms** | La latencia objetivo desde el *commit* en base de datos hasta la recepción en el cliente WebSocket es **p95 < 200 ms**. Es un criterio de aceptación, no un deseo. |
| **C-10** | **Mobile-first y ergonomía operativa** | El barbero opera con una mano entre servicio y servicio: acciones críticas en 1 toque, objetivos táctiles ≥ 48 dp y diseño base de 360 px. |
| **C-11** | **Zero-Login seguro** | El cliente reserva solo con nombre y celular, sin contraseña, pero verificado con un token liviano (OTP) y protegido con límites de tasa. Cero fricción no significa cero control. |
| **C-12** | **Seguridad y privacidad por diseño** | Mínimo privilegio, datos personales minimizados, consentimiento explícito para mensajería y cumplimiento de la Ley 1581 de 2012 (protección de datos personales, Colombia). Ver §8. |
| **C-13** | **Rendimiento y consumo de recursos** | Índices compuestos obligatorios, caché Redis para datos estáticos del comercio, prohibición de consultas N+1 y *assets* livianos para redes 3G/4G. |
| **C-14** | **Observabilidad y auditoría** | Toda operación crítica deja rastro auditable (quién, qué, cuándo, antes/después). Los logs son estructurados, llevan `tenant_id` y `request_id` y nunca contienen datos personales en claro. |
| **C-15** | **Calidad verificable** | Sin prueba automatizada o criterio verificable no hay tarea terminada. Los riesgos de concurrencia, aislamiento y dinero tienen pruebas dedicadas. |
| **C-16** | **Puertas de aprobación** | No se avanza de fase sin revisión humana explícita (G1–G4 y *release gates* por fase). |
| **C-17** | **Simplicidad sostenible** | Se prefiere la solución más simple que cumpla la spec. Toda dependencia nueva exige un ADR en `docs/adr/`. Funcionalidad fuera de la spec va al backlog, no al código. |
| **C-18** | **Tiempo y zona horaria** | Almacenamiento en UTC (ISO 8601); visualización y reglas de agenda en la zona horaria del tenant (por defecto `America/Bogota`). Nunca se compara tiempo local con tiempo UTC sin conversión explícita. |

---

## 3. Estándares de código PHP / Laravel

1. **Versión y lenguaje:** PHP ≥ 8.3 y la última versión estable de Laravel soportada (fijada en `composer.json`). Todos los archivos PHP inician con `declare(strict_types=1);`.
2. **Estilo:** **PSR-12** aplicado con Laravel Pint (preset `psr12` + reglas del repositorio en `pint.json`). El CI falla si `pint --test` reporta diferencias.
3. **Análisis estático:** Larastan/PHPStan **nivel 8** sin errores. Se prohíbe crecer el *baseline*; solo puede disminuir.
4. **Autoload:** PSR-4. Un archivo = una clase/enum/interfaz.
5. **Tipado:** parámetros, retornos y propiedades tipados; `readonly` en *value objects* y DTOs; `enum` respaldados (`backed enums`) para estados, roles y métodos de pago.
6. **Nombres:** clases `PascalCase`, métodos y variables `camelCase`, tablas `snake_case` en plural, columnas `snake_case` en inglés. Los textos de UI van en español mediante archivos de localización.
7. **Controladores delgados:** un controlador valida (`FormRequest`), invoca **un** caso de uso y responde con un `JsonResource`. Sin reglas de negocio ni consultas Eloquent dentro del controlador.
8. **Configuración:** `env()` solo dentro de `config/*.php`.
9. **Migraciones:** nunca se edita una migración ya aplicada; todas definen claves foráneas e índices, y son retrocompatibles (despliegue sin tiempo muerto).
10. **Eventos y *jobs*:** los *broadcasts* se despachan **después del commit** (`afterCommit`); los *jobs* son idempotentes y *tenant-aware*.
11. **Errores:** excepciones de dominio tipadas (`DomainException` con `code` estable y mensaje en español); respuesta HTTP uniforme (RFC 7807 simplificado).
12. **Pruebas:** Pest (o PHPUnit) con pruebas de arquitectura que hacen cumplir la regla de dependencias (§4).

---

## 4. Arquitectura y separación de responsabilidades

```
Interfaces (HTTP API · Livewire/Alpine · Consola · Broadcast channels)
              ↓
Aplicación (casos de uso · DTOs · puertos)
              ↓
Dominio (entidades · value objects · reglas puras · contratos de repositorio)
              ↑
Infraestructura (Eloquent · Redis · Reverb · WhatsApp/SMS · pasarela de pago)
```

### Regla de dependencia

- **Dominio:** PHP puro. **Prohibido** importar `Illuminate\*`, usar facades, `DB`, `Cache`, `Carbon` estático o `now()`. El tiempo entra por una interfaz `Clock`.
- **Aplicación:** orquesta casos de uso, abre transacciones y depende de **interfaces** del dominio (puertos). No conoce HTTP.
- **Infraestructura:** implementa los puertos (repositorios Eloquent, `SlotHoldStore` en Redis, `OtpChannel`, `PaymentGateway`). Los modelos Eloquent viven aquí.
- **Interfaces:** traducen entrada/salida. No contienen reglas de negocio.

### Responsabilidades que no se mezclan

| Responsabilidad | Vive en | Prohibido en |
|---|---|---|
| Cálculo de disponibilidad, máquina de estados, motor de comisiones | `Domain` | Controladores, modelos Eloquent, Livewire |
| Transacciones, locking, idempotencia, orquestación | `Application` | Dominio, controladores |
| Persistencia, Redis, WebSockets, proveedores externos | `Infrastructure` | Dominio, aplicación (solo vía puertos) |
| Validación de forma (tipos, formatos) | `FormRequest` | Dominio (allí solo invariantes de negocio) |
| Presentación (JSON, vistas, widgets) | `Interfaces` / Flutter `presentation` | Aplicación y dominio |

Esta regla se verifica con **pruebas de arquitectura** automatizadas en CI (T-006).

---

## 5. Modelo multi-tenant

1. **Estrategia:** base de datos única, esquema compartido, con discriminador `tenant_id` (`CHAR(36)`, UUID) en **toda** tabla de negocio.
2. **Identificación del tenant:** por dominio o subdominio (`tenants.domain`) en la web pública y el dashboard; por el usuario autenticado (token) en la app del barbero.
3. **Aislamiento por defecto:** todo modelo de negocio usa el *trait* `BelongsToTenant` con un `TenantScope` global y asignación automática de `tenant_id`. Quitar el *scope* (`withoutGlobalScopes`) requiere justificación escrita y una prueba.
4. **Contexto único:** el tenant activo vive en un `TenantContext` por petición/*job*; los *jobs* lo restauran al ejecutarse.
5. **Redis:** toda clave lleva el prefijo `t:{tenantId}:`; los *holds*, OTP, cachés y *locks* no pueden colisionar entre tenants.
6. **WebSockets:** solo canales privados o de presencia con autorización tenant-scoped (`tenant.{tenantId}.*`). Ningún canal público transmite datos de negocio.
7. **Unicidad:** las restricciones únicas son compuestas con `tenant_id` (p. ej. `UNIQUE(tenant_id, phone)`).
8. **Pruebas obligatorias:** existe una suite de **fuga entre tenants** (HTTP, caché, colas y canales) que corre en cada *pull request*.
9. **Cuerpos de petición:** el cliente nunca envía `tenant_id`; si lo hace, se ignora.

---

## 6. Rendimiento y tiempo real

Los siguientes valores son **objetivos de diseño** verificados con pruebas de carga en las puertas G3/G4.

| Métrica | Objetivo |
|---|---|
| Latencia WebSocket (commit → cliente) | **p95 < 200 ms**, p99 < 500 ms |
| Actualización de Pantalla de TV tras un cambio | < 200 ms (p95) |
| `GET` disponibilidad | p95 < 300 ms |
| Confirmación de cita (incluye locking) | p95 < 600 ms |
| Respuesta percibida de acciones en Modo Silla | < 100 ms (UI optimista) y confirmación de servidor p95 < 300 ms |
| Reserva completa del cliente recurrente | ≤ 15 s de interacción |
| Doble reserva ante concurrencia | **0** (50 solicitudes simultáneas a una misma franja → exactamente 1 éxito) |
| Fugas entre tenants | **0** |

Reglas asociadas:

- Índice compuesto obligatorio en `appointments`: `(tenant_id, barber_id, scheduled_date, status)`.
- Caché Redis para servicios, precios, horarios, configuración y reglas de comisión; invalidación explícita al modificarlos.
- *Eager loading* obligatorio; `Model::preventLazyLoading()` activo fuera de producción.
- Reverb escala horizontalmente con Redis; ninguna lógica de negocio depende de que haya un único nodo.
- Si Redis falla, la integridad de reservas sigue garantizada por el *locking* de MySQL (degradación segura, ver RNF-15).

---

## 7. Estándares Flutter

1. **Lenguaje y análisis:** Dart 3 con *null safety*, `very_good_analysis` (o `flutter_lints` estricto). `flutter analyze` sin advertencias; formateo con `dart format`.
2. **Arquitectura:** *feature-first* con Clean Architecture por funcionalidad (`presentation` / `domain` / `data`). Los *widgets* no contienen lógica de negocio ni llaman directamente a la API.
3. **Estado y navegación:** Riverpod y `go_router` (decisión registrada en ADR-007).
4. **Modelos:** inmutables (`freezed`/`json_serializable`); el dinero se maneja como cadena decimal o entero de centavos, nunca `double`.
5. **Mobile-first:** diseño base de **360 × 640 dp**; objetivos táctiles ≥ **48 × 48 dp**; texto ≥ 16 sp; contraste AA; soporte de escala de texto hasta 1,3×.
6. **Modo Silla:** acción primaria en la zona del pulgar, un solo toque para "Cliente en Silla", máximo dos para "Finalizar y Cobrar", con retroalimentación háptica y estado de carga visible.
7. **Conectividad:** estados explícitos (en línea, reconectando, sin conexión); reintentos con `Idempotency-Key`; resincronización con *snapshot* tras reconectar el WebSocket.
8. **Almacenamiento seguro:** tokens en almacenamiento seguro del dispositivo; nunca en preferencias en claro.
9. **Rendimiento web (página de reserva):** HTML crítico en línea, CSS/JS mínimos, caché inmutable de *assets* con *hash* y presupuesto definido en RNF-06 (≤ 250 KB y TTI ≤ 3 s). `deferred components` solo aplica a la cáscara experimental de Flutter Web.
10. **Internacionalización:** ARB con `es-CO` por defecto; ningún texto de UI incrustado en el código.

---

## 8. Seguridad y privacidad

1. **Transporte:** HTTPS/TLS obligatorio; WSS para WebSockets.
2. **Autenticación del personal:** Laravel Sanctum con tokens por dispositivo y revocación; contraseñas con Argon2id o bcrypt (nunca en claro).
3. **Autenticación del cliente (Zero-Login):** OTP de 6 dígitos con TTL de 5 min, almacenado como *hash*, con límite de intentos y de envíos; token de cliente con *ability* restringida a sus propias citas.
4. **Autorización:** *Policies* por rol (`admin`, `barber`) y comprobación de pertenencia al tenant en cada caso de uso.
5. **Límites de tasa:** por IP, por teléfono y por tenant en endpoints públicos.
6. **Validación y salida:** toda entrada validada; salidas con `JsonResource`; protección contra *mass assignment*.
7. **Datos personales:** se almacena el mínimo (nombre y teléfono). Pantalla de TV y vistas públicas muestran solo nombre de pila e inicial. Existe un procedimiento de anonimización a solicitud del titular.
8. **Consentimiento:** las notificaciones por WhatsApp/SMS no transaccionales requieren *opt-in* registrado y permiten *opt-out*.
9. **Secretos:** solo en variables de entorno o gestor de secretos; jamás en el repositorio.
10. **Dependencias:** auditoría automática (`composer audit`, `flutter pub outdated`) en CI.

---

## 9. Calidad y pruebas

| Nivel | Herramienta | Alcance mínimo |
|---|---|---|
| Unitarias | Pest / PHPUnit | Disponibilidad, máquina de estados, comisiones, `Money`, algoritmo de *walk-ins* |
| Arquitectura | Pest Arch / Deptrac | Regla de dependencia entre capas (C-07) |
| Integración | Pest + MySQL + Redis reales (contenedores) | Locking, holds, OTP, transacciones, aislamiento multi-tenant |
| Concurrencia | Pest + procesos paralelos | 50 reservas simultáneas a una franja |
| Contrato/API | Pest + OpenAPI | Estabilidad de `/api/v1` |
| Tiempo real | Pruebas de integración + carga (k6/Artillery) | Entrega de eventos y p95 < 200 ms |
| Flutter | `flutter test` + *golden tests* | Dominio, repositorios, widgets críticos de Modo Silla |
| E2E | Playwright (página de reserva Blade/Alpine) / `integration_test` (app) | Reserva, silla → cobro, fila → TV |
| Manual | Checklist | Accesibilidad, 360 px, dispositivos reales, 3G |

**Cobertura mínima:** ≥ 80 % en `Domain` y `Application` (PHP); ≥ 70 % en `domain` y `data` (Flutter).

---

## 10. Definición de Hecho (DoD)

Una tarea se considera terminada cuando:

- [ ] El código implementa el requisito y sus reglas de negocio.
- [ ] Las validaciones cubren entradas inválidas y casos borde.
- [ ] Existe al menos una prueba automatizada o un criterio verificable asociado.
- [ ] Pint, Larastan (o `flutter analyze`) y las pruebas pasan en CI.
- [ ] Toda tabla/consulta nueva respeta el aislamiento multi-tenant (C-03) y está indexada (C-13).
- [ ] No hay errores ni advertencias en consola, logs ni `flutter analyze`.
- [ ] La UI es usable en 360 px y respeta los objetivos táctiles (si aplica).
- [ ] La documentación afectada (spec, plan, OpenAPI, README) está actualizada.
- [ ] La fila correspondiente de `04-traceability.md` está actualizada.
- [ ] El criterio de aceptación Gherkin asociado fue verificado.

---

## 11. Puertas de aprobación

| Puerta | Qué se revisa | Estado |
|---|---|---|
| **G1 — Especificación** | Alcance, RF, RN, RNF, criterios de aceptación y preguntas abiertas | Aprobada 2026-11-17 |
| **G2 — Plan** | Arquitectura, modelo de datos, fases, riesgos y ADR iniciales | Aprobada 2026-11-17 |
| **G3 — Implementación** | Cada fase (F1, F2, F3) contra su criterio de salida y *release gate* | Pendiente |
| **G4 — Convergencia** | Todos los escenarios Gherkin verificados y trazabilidad completa | Pendiente |

---

## 12. Convenciones

- **Identificadores:** `C-01` (principios), `RF-01`, `RNF-01`, `RN-01`, `US-01`, `ESC-01` (escenarios), `ADR-001`, `OQ-01` (preguntas abiertas).
- **Tareas:** `T-001`; las épicas `E-01`. El primer dígito del número de tarea indica la fase (`T-0xx` F0, `T-1xx` F1, `T-2xx` F2, `T-3xx` F3).
- **Idioma:** nombres de archivos, clases, tablas y código en inglés; textos de UI, mensajes de error y documentación en español.
- **Fechas:** ISO 8601 UTC en almacenamiento y API; hora local del tenant en pantalla.
- **Moneda:** `DECIMAL(10,2)`; formato visual con `Intl.NumberFormat` / `NumberFormatter`; por defecto `COP`.
- **Teléfonos:** formato E.164 normalizado (p. ej. `+573001234567`).
- **IDs:** `tenants.id` UUID; demás entidades `BIGINT UNSIGNED` (según modelo de datos de la spec).
- **API:** versionada en `/api/v1`; respuestas JSON; paginación por cursor o `page`/`per_page`.
- **Ramas:** `main` (protegida), `develop`, `feature/T-xxx-descripcion`.
- **Commits:** `tipo(alcance): descripción` — `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `perf`, `ci`.

---

## 13. Glosario

| Término | Definición |
|---|---|
| **Tenant** | Barbería (comercio) alojada de forma aislada en la plataforma. |
| **Barbero** | Usuario operativo que atiende una silla. |
| **Silla** | Unidad de agenda: un barbero con su disponibilidad. |
| **Zero-Login** | Reserva sin cuenta ni contraseña; identificación por nombre y teléfono con verificación OTP. |
| **Hold** | Bloqueo temporal (180 s) de una franja en Redis mientras el cliente completa su reserva. |
| **Pessimistic Locking** | Bloqueo explícito de filas en MySQL (`SELECT … FOR UPDATE`) durante la escritura final de la cita. |
| **Modo Silla** | Interfaz móvil del barbero de acciones de 1 toque. |
| **Walk-in** | Cliente que llega sin cita y entra a la fila virtual. |
| **Fila Virtual** | Cola de atención en tiempo real, mostrada en la Pantalla de TV. |
| **Pantalla de TV / Kiosco** | Vista de solo lectura de la fila y el estado de las sillas en sala. |
| **Hueco muerto** | Franja libre (por cancelación o baja demanda) susceptible de ser ofertada. |
| **Comisión** | Parte del cobro que corresponde al barbero según su regla (`percentage`, `fixed_service`, `chair_rental`). |
| **Cierre de caja** | Congelamiento de las transacciones de una jornada y cálculo de la liquidación por barbero. |
| **Reverso** | Transacción negativa que corrige una transacción previa sin modificarla. |
| **OTP** | Código de un solo uso enviado por WhatsApp/SMS para verificar el teléfono. |
| **ADR** | *Architecture Decision Record*: registro de una decisión técnica. |

---

## 14. Control de cambios

Cualquier cambio de alcance debe:

1. Registrarse en `01-spec.md` con su ID y justificación.
2. Actualizar `02-plan.md` si afecta arquitectura, modelo de datos o fases.
3. Añadir o ajustar tareas en `03-tasks.md`.
4. Actualizar la matriz de `04-traceability.md`.
5. Pasar por la puerta G1 o G2 según corresponda.
6. Si introduce o cambia una dependencia o decisión técnica, crear o actualizar un ADR.
