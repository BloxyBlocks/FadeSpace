# ADR-003 — Control de concurrencia de reservas: *hold* atómico en Redis + mutex MySQL

- **Estado:** Aceptado
- **Fecha:** 2026-11-14
- **Requisitos:** RF-11, RN-11, RN-13, C-05, C-09, RNF-14, RNF-15, ESC-04, ESC-05
- **Tareas:** T-133 (`GetAvailability`), T-136 (`CreateSlotHold`), T-140 (`ConfirmAppointment`), T-141 (concurrencia)

## Contexto

Dos escrituras pueden competir por la misma franja: dos clientes reservando en paralelo y el barbero creando una
cita manual desde el dashboard. La regla es absoluta: **nunca se asigna una franja dos veces** (RF-11, C-05). El
motivo original del overbooking es la clásica condición de carrera entre "verificar disponibilidad" y "crear la
cita", que no se resuelve con una comprobación previa en PHP.

MySQL 8 no ofrece restricciones de exclusión por rango (a diferencia de PostgreSQL), por lo que el solapamiento
debe resolverse con bloqueo explícito y revalidación dentro de la misma transacción. Además, el *hold* de 180 s
(RN-11) vive en Redis, que puede caer (RNF-15).

## Decisión

**Dos capas complementarias, en este orden:**

1. **Capa 1 — *hold* atómico en Redis (optimista, evita trabajo inútil).**
   `CreateSlotHold` ejecuta un *script* Lua único (EVAL) que, en una sola operación atómica:
   comprueba `t:{tid}:hold:slot:{barberId}:{startEpoch}` y `t:{tid}:hold:session:{sessionId}`,
   rechaza si la franja ya está tomada, y si no, escribe ambas claves con TTL de 180 s y devuelve el `hold_id`.
   Nunca se usa `SETNX` seguido de otro comando: la comprobación y la escritura ocurren en el mismo *script*.
2. **Capa 2 — mutex pesimista en MySQL (autoritativo, decide).**
   `ConfirmAppointment` abre una transacción y ejecuta `SELECT ... FOR UPDATE` sobre la fila del barbero
   (`barbers` del tenant), serializando todas las escrituras de agenda de ese barbero. Dentro de esa transacción:
   1. revalida el *hold* (pertenece a la sesión y sigue vigente),
   2. revalida solapamientos contra `appointments` con los índices `(tenant_id, barber_id, scheduled_date, status)`,
      `time_blocks` y el servicio en curso,
   3. inserta la cita y sus `appointment_services`,
   4. registra la auditoría,
   5. consume el *hold* (borrado de claves) **después** del `COMMIT` exitoso.
   Si cualquier revalidación falla → `409 SLOT_TAKEN` (o `HOLD_EXPIRED`) y *rollback*; el cliente conserva los
   datos para elegir otra franja.

Reglas de implementación:

- **Aislamiento:** `REPEATABLE READ` (valor por defecto de MySQL 8) es suficiente porque todas las escrituras de
  agenda pasan por el mismo mutex; no se usa `SERIALIZABLE`.
- **Orden de bloqueo fijo:** siempre primero `barbers` y después `appointments`, para evitar *deadlocks*. Se
  reintenta como máximo 3 veces con *backoff* exponencial (50/150/350 ms) solo ante `1213` (deadlock).
- **Idempotencia:** `POST /public/appointments` exige `Idempotency-Key`; `UNIQUE(tenant_id, idempotency_key)` en
  `transactions` y la tabla de idempotencia de reservas garantizan una sola cita por intento (DUPLICATE_REQUEST).
- **Respaldo sin Redis (RNF-15):** si Redis no responde, el *hold* se omite y la reserva sigue protegida por la
  capa 2; el cliente ve el aviso de que la franja se confirma solo al final.
- **Nunca** se usa `lockForUpdate` sobre toda la tabla ni bloqueos por rango con `LIKE`; el mutex es siempre una
  fila concreta del barbero del tenant.
- **Cita manual del dashboard y *walk-in*:** reutilizan `ConfirmAppointment` para no duplicar la lógica de locking.

## Alternativas descartadas

| Alternativa | Por qué no |
|---|---|
| Solo *hold* en Redis | Redis no es la fuente de verdad (puede perderse por reinicio o *eviction*) y no cubre la cita manual del dashboard ni el *walk-in*. |
| Solo `SELECT ... FOR UPDATE` sobre `appointments` | Se bloquean filas que aún no existen; el *gap lock* resultante es impredecible y no impide insertar solapamientos. |
| `UNIQUE(barber_id, scheduled_start)` | Solo detecta colisiones de inicio idéntico, no solapamientos parciales (RN-13). Se mantiene como red de seguridad, no como solución. |
| *Advisory lock* de MySQL (`GET_LOCK`) | Fuera de la transacción, no ligado al ciclo de vida de la fila y difícil de probar; el mutex de fila ya serializa por barbero. |
| Cola de reservas de un solo hilo (*worker*) | Introduce latencia y un punto único de fallo; contradice el objetivo p95 < 600 ms de confirmación (RNF-02). |

## Consecuencias

**Positivas**

- El invariante "una franja, una cita" se sostiene bajo concurrencia real, incluso con la cita manual compitiendo.
- La capa 1 evita que 50 peticiones simultáneas lleguen a la base de datos.
- Degradación segura: sin Redis se pierde rapidez, no corrección.

**Negativas y mitigaciones**

- El mutex por barbero serializa la agenda de ese barbero → aceptable: una barbería tiene pocas sillas y las
  escrituras son cortas (una transacción, sin llamadas externas dentro de ella).
- Nunca se debe llamar a WhatsApp/SMS ni a Reverb **dentro** de la transacción; los *broadcasts* van con
  `afterCommit` (D-05).
- Riesgo de *hold* huérfano si el cliente abandona → TTL 180 s y liberación explícita en `DELETE /public/holds/{id}`.

## Verificación

- `tests/Concurrency/ConfirmAppointmentTest`: 50 procesos intentan la misma franja → exactamente 1 cita y 49
  `409 SLOT_TAKEN`; repetido para cita manual concurrente.
- `tests/Integration/Booking/SlotHoldTest`: *script* Lua atómico, TTL y consumo del hold.
- `tests/Integration/Resilience/RedisDownTest`: reserva correcta con Redis caído (ESC-25).
- `tests/Feature/Booking/IdempotencyTest`: mismo `Idempotency-Key` → una sola cita, misma respuesta.

## Referencias

- `docs/01-spec.md` §6 (RN-11, RN-13), §9 ESC-04/ESC-05.
- `docs/02-plan.md` §3 (D-03, D-04, D-05), §6 claves Redis, §12 riesgos.
- `docs/00-constitucion.md` C-05, C-15.
