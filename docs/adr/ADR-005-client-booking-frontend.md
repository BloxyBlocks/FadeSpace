# ADR-005 — Entrada del cliente: página de reserva liviana en lugar de Flutter Web

- **Estado:** Aceptado — ratificado el 2026-11-14; enmiendas aplicadas al cerrar G2 (2026-11-17)
- **Fecha:** 2026-11-14
- **Ratificación:** Diego Alejandro Zamora Gallego (decisión de producto, 2026-11-14). La re-planificación de
  T-160…T-165 y la enmienda de `02-plan.md` §1/§4/§7/§9/§10/§11/§12 se aplicaron el 2026-11-17 al cerrar G2 (T-007).
- **Requisitos:** RNF-06, RNF-08, C-13, C-17, OQ-06
- **Tareas:** T-009 (*spike*), T-160…T-165 (re-planificar), T-343

## Contexto

RNF-06 fija un presupuesto duro para la PWA del cliente: **2 MB transferidos en la primera carga** y
**TTI ≤ 6 s en 3G rápida** con dispositivo de gama media. OQ-06 deja abierta la alternativa de una página de
reserva liviana si Flutter Web no cumple.

El *spike* T-009 construyó la cáscara real de `apps/client_pwa` (Flujo de reserva completo en Flutter 3.50) y midió
la carga en dos variantes: **dart2js + CanvasKit** (compilación por defecto) y **wasm + skwasm**.

### Medición 1 — Transferencia real en navegador (Lighthouse 12, móvil emulado)

Ejecución `--throttling.rttMs=150 --throttling.throughputKbps=1600 --throttling.cpuSlowdownMultiplier=4`
(3G rápida + CPU de gama media), servidor local con brotli. Evidencia: `spikes/t009/lighthouse-3g.json`.

| Recurso | Transferido |
|---|---|
| `canvaskit.wasm` (CDN `gstatic.com`, variante *chromium*) | 1.567.970 B |
| `main.dart.js` | 644.569 B |
| `Roboto` `.woff2` (CDN `fonts.gstatic.com`) | 64.023 B |
| `canvaskit.js` (CDN) | 24.836 B |
| `flutter_bootstrap.js` | 5.098 B |
| icono PWA + HTML + manifest + fuentes | 9.715 B |
| **Total primera carga** | **2.316.261 B ≈ 2,32 MB** |

Métricas de la misma corrida:

| Métrica | Valor | Presupuesto |
|---|---|---|
| First Contentful Paint | 4,671 s | — |
| Speed Index | 12,696 s | — |
| *Main thread work* | 2,53 s | — |
| *JS bootup* | 2,13 s | — |
| CLS | 0 | — |
| LCP / TBT / TTI | **no calculables** (`LanternError: NO_LCP`) | TTI ≤ 6 s |

Dos hallazgos adicionales, ambos estructurales:

1. **No hay elemento LCP**: CanvasKit pinta sobre un `<canvas>`, así que las herramientas estándar no pueden medir
   TTI ni puntuar el rendimiento. El presupuesto de RNF-06 no sería verificable con Lighthouse/WebPageTest.
2. **Dependencia de terceros en la ruta crítica**: CanvasKit y la fuente Roboto se descargan de `gstatic.com`. Eso
   añade dos orígenes externos (latencia, disponibilidad, privacidad bajo la Ley 1581) y solo se evita con
   `--no-web-resources-cdn`, que no reduce bytes.

### Medición 2 — Variante wasm + skwasm (mejor caso de Flutter Web)

Compresión brotli de calidad 11 sobre los recursos de primera carga de `build/web_wasm`:

| Recurso | Crudo | Brotli |
|---|---|---|
| `main.dart.wasm` | 2.293.975 B | 660.683 B |
| `canvaskit/skwasm.wasm` | 3.612.036 B | 1.215.580 B |
| `canvaskit/skwasm.js` | 63.858 B | 14.971 B |
| `flutter_bootstrap.js` | 14.868 B | 4.931 B |
| `index.html` | 2.151 B | 737 B |
| **Total** | 5.986.888 B | **1.897.902 B ≈ 1,90 MB** |

Es decir: **el mejor caso posible de Flutter Web queda a ~5 % del límite de 2 MB**, sin contar la fuente, los
iconos ni los `NOTICES`, y a cambio de:

- exigir `Cross-Origin-Opener-Policy: same-origin` + `Cross-Origin-Embedder-Policy: require-corp` (SharedArrayBuffer)
  en todo el sitio, lo que rompe cualquier recurso externo (mapas, píxeles, soporte) que no envíe CORP;
- depender de navegadores con *garbage collection* de Wasm (Safari/iOS quedó rezagado; el *fallback* JS vuelve a
  los 2,32 MB);
- seguir sin LCP/TTI medibles.

## Decisión

1. **El embudo público de reserva se sirve como página server-rendered liviana** (Laravel Blade + Alpine.js +
   CSS propio, sin framework de UI), en el dominio del tenant y con **presupuesto de primera carga ≤ 250 KB** y
   **TTI ≤ 3 s en 3G rápida**. Es la URL que recibe el cliente desde WhatsApp, QR y enlaces externos.
2. **Flutter Web queda fuera de la ruta crítica de F1.** `apps/client_pwa` se conserva como cáscara de
   experimentación (ya construida en este *spike*) y solo se promovería si en el futuro se acepta explícitamente
   el coste de los 2 MB; cualquier promoción requiere un ADR que reemplace a este.
3. **La app Flutter del barbero no se ve afectada**: sigue siendo la app nativa (Android/iOS), donde el peso de
   descarga no compite con el presupuesto de 3G de una página web.
4. **Re-planificación aplicada en G2** (control de cambios, constitución §14): T-160…T-165 pasan de "scaffold
   Flutter" a "vistas Blade/Alpine + Playwright E2E". `02-plan.md` §1/§4/§7/§9/§10/§11/§12 y `04-traceability.md`
   quedaron actualizados el 2026-11-17 en la misma puerta.
5. **Requisitos que la página liviana debe cumplir igualmente**: módulo ES, sin *blocking CSS*, `Cache-Control`
   inmutable para *assets* con hash, HTML crítico en línea ≤ 14 KB, OTP y *hold* con Cuenta Regresiva, accesibilidad
   WCAG 2.1 AA (RNF-09) y `es-CO` (RNF-16).

## Alternativas descartadas

| Alternativa | Por qué no |
|---|---|
| Flutter Web (dart2js + CanvasKit) por defecto | 2,32 MB > 2 MB, FCP 4,7 s, Speed Index 12,7 s y TTI no medible. Incumple RNF-06 de forma objetiva. |
| Flutter Web con `--wasm` + cabeceras COOP/COEP | 1,90 MB es el mejor caso teórico, sin margen, con restricciones de navegador y rompe recursos externos. |
| Flutter Web con recursos auto-alojados (`--no-web-resources-cdn`) | Elimina los orígenes externos (bueno) pero no reduce los 2,32 MB (insuficiente). |
| Aceptar una enmienda a RNF-06 (subir el presupuesto a 3 MB) | Contradice C-13 ("assets livianos para 3G/4G") y el objetivo de reserva en ≤ 15 s para cliente recurrente. Sería una decisión de producto, no técnica; no hay evidencia de que el negocio lo necesite. |
| PWA en React/Vue con SSR | Cumpliría el presupuesto, pero agrega un tercer stack (además de Laravel y Flutter) y duplica despliegue; Blade + Alpine reutiliza el backend existente. |

## Consecuencias

**Positivas**

- El presupuesto de 2 MB pasa a ser holgadamente verificable (Lighthouse reporta LCP/TTI reales sobre HTML).
- Menos superficie de mantenimiento para F1: una sola base de código web (Blade) en lugar de dos.
- Sin dependencia de CDNs de terceros en la ruta de conversión (privacidad y disponibilidad).
- La reserva funciona incluso en navegadores antiguos de gama baja, que es el parque real de clientes en Colombia.

**Negativas y mitigaciones**

- Se pierde la reutilización de widgets entre barbero y cliente → los *design tokens* se comparten por CSS
  variables generadas desde la misma paleta de `fadespace_ui` (documentar en T-343).
- `apps/client_pwa` queda como código no desplegado → se conserva etiquetado como experimento y se excluye de CI
  obligatorio si empieza a costar mantenimiento.
- La decisión contradice `02-plan.md` §1 → **quedó ratificada el 2026-11-14** y la enmienda formal de
  `02-plan.md` §1/§4/§7/§9/§10/§11/§12 y de `04-traceability.md` (T-160…T-165) **se ejecutó el 2026-11-17** al
  cerrar G2 (T-007), con registro CC-02 (constitución §14).

## Verificación

- `spikes/t009/size.json` (compresión por recurso), `spikes/t009/lighthouse-3g.json` (transferencia real y
  métricas), `spikes/t009/size-probe.cjs` y `static-server.cjs` (reproducibilidad).
- F1/T-164: presupuesto automatizado en CI (`lhci autorun` con *assertions* `total-byte-weight ≤ 250 000` e
  `interactive ≤ 3000` sobre la página de reserva).
- F1/T-165: Playwright mide la reserva completa de un cliente recurrente ≤ 15 s.

### Límites explícitos de esta evidencia

- No se midió en un dispositivo Android/iOS de gama media real ni con radio 3G/4G real: la corrida es emulada
  (Lighthouse `simulate`). El margen de 2,32 MB sobre 2 MB es tan amplio que la conclusión no depende de esa
  diferencia, pero el TTI exacto de la página liviana **deberá** medirse en WebPageTest con dispositivo real en
  T-164 antes de cerrar RNF-06.
- No se probó el escalado de WebSockets en web (irrelevante tras esta decisión, pasa a T-206/T-207 en móvil).

## Referencias

- `docs/01-spec.md` RNF-06, RNF-08, RNF-09, OQ-06.
- `docs/02-plan.md` §1 (clientes), §4 (estructura Flutter), §7 rutas, §9 pruebas E2E, §10 ADR-005, §11 fases y §12 riesgos.
- `docs/00-constitucion.md` C-13, C-17, §14 control de cambios.

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-14 | ADR aceptado y ratificado por el autor (OQ-06 resuelta). |
| 2026-11-17 | G2 aprobada: enmiendas de `02-plan.md` y `04-traceability.md` aplicadas; T-160…T-165 re-planificadas. |
