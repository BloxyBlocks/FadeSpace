# ADR-004 — Cliente WebSocket de Reverb en Flutter: protocolo Pusher propio

- **Estado:** Aceptado
- **Fecha:** 2026-11-14
- **Requisitos:** RF-27, RF-28, RNF-01, RNF-15, C-09, ESC-21
- **Tareas:** T-008 (*spike*), T-201…T-208, T-228

## Contexto

La app del barbero (Flutter móvil) y la PWA escuchan eventos de Laravel Reverb: citas, fila virtual, estado de
sillas y bloqueos. El requisito es latencia **p95 < 200 ms** desde el *commit* hasta la recepción en el cliente
(C-09) y reconexión con resincronización por *snapshot* (RF-28).

Reverb habla el **protocolo Pusher** (`pusher:connection_established`, `pusher:subscribe`, `pusher:ping`). En
Flutter existían tres caminos: el plugin `pusher_channels_flutter`, `laravel_echo` + `pusher-js` (solo web), o un
cliente propio sobre un WebSocket genérico.

El *spike* T-008 se ejecutó con un cliente propio mínimo (`packages/fadespace_realtime/tool/latency_probe.dart`)
contra un Reverb local, midiendo `recibido_en_cliente_utc − emitted_at_utc` con 40 eventos a 200 ms de intervalo
(`spikes/t008/latency-40.json`):

| Métrica | Valor medido (loopback) |
|---|---|
| Eventos recibidos | 40 / 40 |
| p50 | **17,808 ms** |
| p95 | **18,820 ms** |
| Mínimo | 2,791 ms |
| Máximo | 31,773 ms |

> Observación del *spike*: usar `localhost` en Windows resolvía a `::1` y añadía ~200 ms de sobrecarga artificial
> (p50 221 ms). Con `REVERB_HOST=127.0.0.1` la latencia se estabilizó en ~18 ms. Conclusión operativa: en el
> servidor, `REVERB_HOST` debe apuntar al nombre del servicio interno y en el cliente al host real, nunca a un
> alias ambiguo.

## Decisión

Implementar el cliente en `packages/fadespace_realtime` sobre `web_socket_channel` (multiplataforma: `dart:io` en
móvil, `dart:html`/`WebSocket` en web), con:

1. **Protocolo Pusher explícito**: socket en `{scheme}://{host}:{port}/app/{key}?protocol=7&client=fadespace&version=x`,
   `pusher:subscribe` por canal, respuesta a `pusher:ping` y manejo de `pusher:error`.
2. **Transporte abstracto** (`RealtimeTransport`) para poder inyectar un transporte falso en pruebas y evitar
   dependencias de red en unit tests.
3. **Máquina de estados explícita** (`disconnected`, `connecting`, `connected`, `reconnecting`) y flujo
   `connectionStates` para que la UI muestre el estado (C-13, RNF-15).
4. **Reconexión con *backoff* exponencial + jitter** (1 s, 2 s, 4 s… tope 30 s) y re-suscripción automática de los
   canales registrados; tras reconectar, la app pide el *snapshot* REST (T-205) para cerrar huecos.
5. **Autorización de canales privados** vía `ChannelAuthorizer` que llama a `/broadcasting/auth` con el token del
   dispositivo; el `channel_data` devuelto se reenvía tal cual al `pusher:subscribe`.
6. **Degradación segura**: si no hay conexión tras N intentos o el *handshake* falla, la app cae a sondeo cada 15 s
   (RNF-15) sin cambiar de capa de dominio.
7. **Observabilidad**: cada evento recibido expone `emitted_at`; el cliente mide latencia y la reporta para el
   monitor sintético (T-206).

## Alternativas descartadas

| Alternativa | Por qué no |
|---|---|
| `pusher_channels_flutter` | Plugin de terceros con mantenimiento irregular, API de *callbacks* imperativa, soporte web limitado y difícil de probar sin red; añade peso y dependencia de plataforma. |
| `laravel_echo` + `pusher-js` | Solo web; obliga a dos implementaciones distintas (JS y Dart) y a un puente JS en Flutter Web. |
| gRPC / SSE | Reverb es Pusher por diseño (D-02, RNF-18); SSE no soporta canales privados con autorización bidireccional y pierde el escalado con Redis. |
| Sondeo REST cada 5 s como mecanismo principal | Consumo de batería y backend desproporcionado; viola el objetivo de latencia y el criterio de 1.000 conexiones (T-207). |

## Consecuencias

**Positivas**

- Una sola implementación Dart para móvil y web, con pruebas unitarias sin red (transporte falso).
- Latencia medida muy por debajo del presupuesto en condiciones controladas (p95 ~19 ms de extremo a extremo).
- Control total del ciclo de reconexión, que es donde fallan la mayoría de las apps en sala (cobertura móvil
  irregular).

**Negativas y mitigaciones**

- Mantenemos ~300 líneas de protocolo propio → cubierto con pruebas del transporte y del flujo de suscripción;
  el protocolo Pusher es estable y pequeño.
- Sin verificación en dispositivos reales ni bajo carga → T-206 (monitor sintético) y T-207 (1.000 conexiones con
  p95 < 200 ms) son la validación real; el *spike* en loopback **no** demuestra el requisito de producción.
- Los *broadcasts* deben ser `afterCommit` (D-05) para no generar eventos fantasma.

## Verificación

- `packages/fadespace_realtime/test/realtime_client_test.dart`: conexión, suscripción, decodificación y
  reconexión con transporte falso.
- `spikes/t008/latency-40.json` + `spikes/t008/emit-40.log`: evidencia reproducible del *spike*.
- F2: `tests/Realtime/EventDeliveryTest` y `tests/Load/ws-latency.js` (p95 < 200 ms bajo carga).

## Referencias

- `docs/01-spec.md` RNF-01, RF-27, RF-28.
- `docs/02-plan.md` §3 (D-05), §11 riesgos, §10 ADR-004.
- `docs/00-constitucion.md` C-09, C-13.
