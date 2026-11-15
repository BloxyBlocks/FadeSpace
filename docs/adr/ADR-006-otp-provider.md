# ADR-006 — Proveedor de OTP: SMS transaccional en F1, WhatsApp Cloud API en F3

- **Estado:** Propuesto (depende de OQ-03 y de validación de costos con negocio)
- **Fecha:** 2026-11-14
- **Requisitos:** RF-10, RN-22, RN-23, C-11, C-12
- **Tareas:** T-137, T-138, T-230…T-232 (F3 WhatsApp), T-345 (*runbook*)

## Contexto

El cliente reserva sin contraseña: nombre + celular, verificado con un OTP de 6 dígitos (RN-22/RN-23). El mensaje
es la única barrera entre un teléfono mal escrito y una cita perdida, así que la entregabilidad importa más que el
precio unitario.

Condiciones del proyecto:

- Operación en **Colombia**; los clientes reciben el OTP desde un enlace de WhatsApp o un QR en la barbería.
- F1 necesita un canal **hoy**, con credenciales de prueba y sin contrato corporativo ni trámite de empresa local.
- F3 incorpora **WhatsApp Business API** con plantillas aprobadas y notificaciones no transaccionales (RN-25).
- El código nunca debe conocer el proveedor: la interfaz es `OtpChannel` (puerto de dominio/aplicación).

## Decisión

1. **F1 — SMS transaccional con Twilio Programmable Messaging** detrás de `SmsOtpChannel`:
   - *Sender* alfanumérico o número local colombiano según disponibilidad de la cuenta.
   - Mensaje corto en español, sin enlaces ni datos personales: `"FadeSpace: tu código es 123456. Vence en 5 min."`
   - Verificación de firma `X-Twilio-Signature` en el *webhook* de estado y *replay protection* por `MessageSid`.
   - *Idempotencia*: el envío se registra en `notification_logs` con el `provider_message_id`; reintentos con la
     misma clave no generan segundo SMS.
2. **Implementaciones por entorno:** `LogOtpChannel` (local y test, escribe el código en el log y en la respuesta
   solo con `APP_ENV=local`), `SmsOtpChannel` (staging/producción) y `FakeOtpChannel` (pruebas).
3. **F3 — Meta WhatsApp Cloud API** como canal preferente para notificaciones y recordatorios, reutilizando
   `OtpChannel`; el OTP seguirá pudiendo salir por SMS como *fallback* si la plantilla no está aprobada o el
   cliente no dio *opt-in*.
4. **Reglas de envío** (independientes del proveedor): máximo 3 envíos/hora por teléfono y 10/hora por IP
   (RN-23), 5 intentos por código, TTL 300 s, hash en Redis, un solo uso.
5. **Costos y alertas:** presupuesto mensual por tenant con alerta al 80 %; si se supera, se degrada a un único
   envío por reserva y se avisa al administrador (no se bloquea la reserva).
6. **Datos personales:** solo se envía el teléfono al proveedor; el contenido no incluye nombre completo ni
   dirección (minimización, C-12). El proveedor debe ofrecer DPA y retención configurable.

## Alternativas evaluadas

| Proveedor / vía | A favor | En contra | Veredicto |
|---|---|---|---|
| **Twilio** | Cobertura CO probada, credenciales de prueba inmediatas, *webhooks* firmados, SDK/HTTP simple, buena documentación de entregabilidad | Costo por mensaje más alto que agregadores locales; *sender ID* alfanumérico sujeto a registro | **Elegido para F1** |
| Amazon SNS | Muy económico, buena integración AWS | Configuración de *sender* y entregabilidad en CO menos predecible; menor visibilidad por mensaje | Reserva |
| Agregador local colombiano | Mejor precio y *shortcode* local | Requiere contrato y empresa constituida; integración y soporte variables | Backlog (F3 si el volumen lo justifica) |
| WhatsApp Cloud API desde F1 | Mayor tasa de lectura, sin costo por SMS | Requiere plantillas aprobadas y *opt-in*; el flujo de verificación tarda semanas | Se adelanta a F3 |
| Solo correo electrónico | Gratis | El cliente objetivo no usa correo para reservar; contradice C-11 | Descartado |

## Consecuencias

**Positivas**

- Un canal real en F1 sin comprometer la arquitectura: el dominio solo conoce `OtpChannel`.
- Cambiar de proveedor es implementar una clase y ajustar configuración, no tocar casos de uso.
- El mismo puerto sirve para OTP y para recordatorios de F3.

**Negativas y mitigaciones**

- Dependencia de un proveedor externo en el camino crítico de la reserva → *fallback* documentado (`LogOtpChannel`
  en local; en producción, reintento y mensaje de "reenviar código"), *timeout* de 5 s y *circuit breaker*.
- Costo variable por tenant → presupuesto y alerta al 80 %, métrica de SMS por reserva.
- Registro del *sender* en Colombia puede tardar → usar el número de prueba de Twilio en staging y planificar el
  registro antes de F1 (responsable: negocio).
- OQ-03 sigue abierta: este ADR fija el **valor por defecto técnico**, no la decisión comercial definitiva.

## Verificación

- `tests/Feature/Auth/OtpTest.php` con `FakeOtpChannel`: hash, TTL, un solo uso, 5 intentos, límites RN-23.
- `tests/Integration/Messaging/TwilioSignatureTest.php`: firma inválida → `403`; *replay* → ignorado.
- Staging: envío real a un número colombiano con medición de tiempo de entrega y tasa de fallo (T-138).
- `notification_logs` con `provider_message_id` para conciliar costo y entregabilidad.

## Referencias

- `docs/01-spec.md` §6 (RN-22…RN-25), RF-10, OQ-03.
- `docs/02-plan.md` §5 (servicios externos), §11 riesgos, §10 ADR-006.
- `docs/00-constitucion.md` C-11, C-12.
