# Especificación funcional y técnica — FadeSpace

**Versión:** 1.1  
**Estado:** Aprobada en G1 y actualizada en G2 el 2026-11-17 · OQ-01…OQ-07 resueltas en §12  
**Autor:** Diego Alejandro Zamora Gallego  
**Iniciativa:** Bloxysoft  
**Producto:** Plataforma SaaS multi-tenant de gestión, agendamiento y cobros para barberías  
**Stack:** Laravel · MySQL · Redis · Laravel Reverb · Flutter  
**Depende de:** `00-constitucion.md`

---

## 1. Visión

Las barberías locales operan con agendas de papel, cuadernos y conversaciones desordenadas de WhatsApp. Las soluciones de agendamiento tradicionales fallan en este contexto porque:

- Obligan al cliente a registrarse, verificar un correo o instalar una app antes de reservar.
- Ignoran a los clientes espontáneos (*walk-ins*), que son parte esencial del negocio.
- No se adaptan al cobro local (efectivo, Nequi, Daviplata) ni al cálculo diario de comisiones o alquiler de silla.
- Ofrecen interfaces administrativas complejas e impracticables para un barbero en plena jornada.

**FadeSpace** es una plataforma SaaS que digitaliza la operación diaria de la barbería con tres diferenciadores: **reserva Zero-Login**, **Modo Silla de 1 toque** y **control financiero centralizado en tiempo real**.

### Objetivos medibles

- El cliente agenda en **≤ 15 segundos** (cliente recurrente) sin crear contraseña.
- El barbero inicia un servicio con **1 toque** y cobra con **≤ 2 toques**.
- **0 reservas dobles** bajo concurrencia.
- Eventos de agenda y fila llegan a todos los clientes conectados con **p95 < 200 ms**.
- La liquidación de comisiones por barbero es **exacta al centavo** y se calcula sin intervención manual.
- **0 fugas** de datos entre tenants.

---

## 2. Alcance

### Incluido en v1.0

- Plataforma multi-tenant con aislamiento de datos y planes de suscripción.
- Dashboard administrativo web (Livewire/Alpine): barberos, servicios, horarios, agenda, caja y comisiones.
- Reserva **Zero-Login** (página Blade/Alpine; ADR-005) con verificación OTP.
- Control de concurrencia: *Cache Hold* (Redis) + *Pessimistic Locking* (MySQL).
- App del barbero (Flutter): agenda, **Modo Silla**, cobro rápido, bloqueo rápido y métricas diarias.
- **Fila Virtual** y gestión de *walk-ins*, con **Pantalla de TV / Kiosco**.
- Sincronización en tiempo real con Laravel Reverb.
- **Motor de comisiones**: porcentaje, tarifa fija por servicio y alquiler de silla.
- Cierre de caja y liquidación por barbero.
- **Motor de rescate de huecos muertos**.
- Notificaciones por WhatsApp Business API (confirmación, recordatorio, ofertas).
- Suscripciones SaaS con pasarela de pago y *feature gating* por plan.
- Auditoría de operaciones críticas.

### Excluido de v1.0

- Multi-sucursal (add-on posterior; v1.0 asume **una sede por tenant**, ver OQ-02).
- Módulo de inventario y comisiones por venta de productos (add-on posterior).
- Propinas, descuentos, cupones y pagos en línea de la cita por parte del cliente.
- Facturación electrónica / contabilidad.
- Aplicación nativa para el cliente final (se atiende vía página de reserva web).
- Panel interno de plataforma (*super-admin*) de Bloxysoft; en F1–F2 los tenants se aprovisionan por comando de consola.
- Notificaciones *push* nativas (FCM/APNs) para el barbero.
- Selección de servicios habilitados por barbero (todos los barberos ofrecen todos los servicios activos).
- Integración con calendarios externos y pasarelas de pago del cliente final.

---

## 3. Actores y permisos

| Actor | Descripción | Autenticación |
|---|---|---|
| **Cliente** | Persona que reserva o llega sin cita | Sin contraseña: nombre + teléfono + OTP; token de cliente de alcance limitado |
| **Barbero** (`barber`) | Atiende una silla | Teléfono + contraseña (Sanctum), app Flutter |
| **Administrador** (`admin`) | Dueño o gerente del tenant | Teléfono/correo + contraseña, dashboard web |
| **Pantalla de TV** | Dispositivo de sala, solo lectura | *Display token* revocable |
| **Sistema** | Tareas programadas, rescate de huecos, notificaciones | Interno |

| Acción | Admin | Barbero | Cliente | TV |
|---|:--:|:--:|:--:|:--:|
| Ver disponibilidad y reservar | ✅ | ✅ | ✅ | ❌ |
| Cancelar/reprogramar cita propia | — | — | ✅ | ❌ |
| Ver agenda propia | ✅ | ✅ | ✅ (su cita) | ❌ |
| Ver agenda de todas las sillas | ✅ | ❌ | ❌ | ✅ (solo fila) |
| "Cliente en Silla" / "Finalizar y Cobrar" (cita propia) | ✅ | ✅ | ❌ | ❌ |
| Registrar *walk-in* | ✅ | ✅ | ❌ | ❌ |
| Bloqueo rápido de tiempo (silla propia) | ✅ | ✅ | ❌ | ❌ |
| Gestionar barberos, servicios, horarios y comisiones | ✅ | ❌ | ❌ | ❌ |
| Ver caja, liquidaciones y reportes | ✅ | ❌ (solo su liquidación) | ❌ | ❌ |
| Cerrar caja | ✅ | ❌ | ❌ | ❌ |
| Registrar reverso de transacción | ✅ | ❌ | ❌ | ❌ |
| Gestionar plan, TV y configuración | ✅ | ❌ | ❌ | ❌ |
| Ver auditoría | ✅ | ❌ | ❌ | ❌ |

---

## 4. Historias de usuario

| ID | Historia | Prioridad | Fase |
|---|---|---|---|
| US-01 | Como cliente quiero reservar sin crear una cuenta para agendar en segundos. | Must | F1 |
| US-02 | Como cliente quiero elegir servicio, barbero o "primer disponible" y ver solo franjas realmente libres. | Must | F1 |
| US-03 | Como cliente quiero que mi franja se reserve mientras completo mis datos para que nadie me la quite. | Must | F1 |
| US-04 | Como cliente quiero consultar, cancelar o reprogramar mi cita desde el celular. | Must | F1 |
| US-05 | Como administrador quiero gestionar barberos, servicios, precios y horarios. | Must | F1 |
| US-06 | Como administrador quiero ver la agenda de todas las sillas en un solo tablero. | Must | F1 |
| US-07 | Como barbero quiero ver mi agenda del día actualizada en vivo. | Must | F2 |
| US-08 | Como barbero quiero marcar "Cliente en Silla" con un toque. | Must | F2 |
| US-09 | Como barbero quiero finalizar y cobrar eligiendo el método de pago en segundos. | Must | F2 |
| US-10 | Como barbero quiero bloquear mi tiempo (almuerzo, imprevistos) con un toque. | Must | F2 |
| US-11 | Como barbero quiero ver cuánto he ganado hoy. | Should | F2 |
| US-12 | Como recepcionista o barbero quiero agregar un *walk-in* y que el sistema calcule su turno. | Must | F2 |
| US-13 | Como cliente en sala quiero ver en una TV quién está en silla, quién sigue y cuánto falta. | Must | F2 |
| US-14 | Como cliente quiero ver mi turno y tiempo estimado de espera desde el celular. | Should | F2 |
| US-15 | Como administrador quiero que el sistema calcule la comisión de cada barbero automáticamente. | Must | F2 |
| US-16 | Como administrador quiero cerrar la caja del día con desglose por método de pago y barbero. | Must | F3 |
| US-17 | Como administrador quiero liquidar a cada barbero según su modelo (porcentaje, fijo o alquiler). | Must | F3 |
| US-18 | Como administrador quiero que el sistema ofrezca huecos libres a clientes frecuentes. | Should | F3 |
| US-19 | Como cliente quiero recibir confirmaciones y recordatorios por WhatsApp. | Should | F3 |
| US-20 | Como dueño quiero contratar y pagar mi plan de suscripción en línea. | Must | F3 |
| US-21 | Como administrador quiero ver quién hizo cada cambio crítico. | Should | F1 |
| US-22 | Como cliente quiero ver mi historial de servicios. | Could | F3 |

---

## 5. Requisitos funcionales

| ID | Requisito | Prioridad | Fase |
|---|---|---|---|
| **Tenancy e identidad** | | | |
| RF-01 | Aprovisionamiento de tenant: dominio único, nombre, plan, configuración inicial y administrador (comando de consola en F1; *onboarding* autoservicio en F3). | Must | F1 |
| RF-02 | Resolución del tenant por dominio/subdominio y aislamiento automático de datos mediante *scope* global. | Must | F1 |
| RF-03 | Autenticación del personal (admin/barbero) con tokens por dispositivo, cierre de sesión y revocación. | Must | F1 |
| RF-04 | Gestión de barberos y usuarios del tenant: rol, comisión (`commission_type`, `commission_rate`), activación/desactivación. | Must | F1 |
| RF-05 | Catálogo de servicios: nombre, precio, duración, *buffer* y estado activo. | Must | F1 |
| RF-06 | Configuración del tenant: horario de atención, zona horaria, colores de marca, cuadrícula de franjas, antelación mínima/máxima, ventana de cancelación y tiempo de gracia. | Must | F1 |
| RF-07 | Horarios de trabajo por barbero y bloqueos programados (vacaciones, ausencias). | Must | F1 |
| **Reserva Zero-Login** | | | |
| RF-08 | Consulta de disponibilidad por servicio(s), barbero (o "primer disponible") y fecha, descontando citas, bloqueos y *holds* activos. | Must | F1 |
| RF-09 | *Hold* temporal de 180 s sobre la franja elegida, vinculado a la sesión del cliente. | Must | F1 |
| RF-10 | Identificación del cliente con nombre y teléfono, verificada con OTP por WhatsApp/SMS; sin contraseña. | Must | F1 |
| RF-11 | Confirmación de la cita con *Pessimistic Locking*: nunca se asigna una franja dos veces. | Must | F1 |
| RF-12 | Asignación automática del barbero con la opción "Primer disponible". | Must | F1 |
| RF-13 | El cliente consulta, cancela o reprograma su cita mediante su token de cliente o enlace. | Must | F1 |
| RF-14 | Creación/actualización automática del cliente por teléfono (`visits_count`, barbero preferido, notas). | Must | F1 |
| RF-15 | Ciclo de vida de la cita como máquina de estados (`pending`, `confirmed`, `in_chair`, `completed`, `cancelled`, `no_show`). | Must | F1 |
| RF-16 | Cancelación y marcado de `no_show` por barbero/admin; política de ventana de cancelación del cliente. | Must | F1 |
| RF-17 | El administrador crea, mueve y cancela citas manualmente desde el tablero. | Must | F1 |
| **App del barbero / Modo Silla** | | | |
| RF-18 | Agenda diaria del barbero actualizada en tiempo real. | Must | F2 |
| RF-19 | **Modo Silla:** "Cliente en Silla" en 1 toque (`confirmed` → `in_chair`, registra `actual_start`). | Must | F2 |
| RF-20 | **Finalizar y Cobrar:** cierra la atención, registra el método de pago y genera la transacción con su comisión. | Must | F2 |
| RF-21 | **Bloqueo Rápido de Tiempo:** pausa la silla por intervalos predefinidos con 1 toque. | Must | F2 |
| RF-22 | Métricas diarias del barbero: servicios atendidos y ganancias. | Should | F2 |
| **Fila virtual y walk-ins** | | | |
| RF-23 | Registro de *walk-in* con algoritmo de inserción que respeta las citas confirmadas. | Must | F2 |
| RF-24 | Fila Virtual con posición y tiempo estimado de espera recalculado ante cambios. | Must | F2 |
| RF-25 | Modo **Pantalla de TV / Kiosco**: vista de solo lectura en tiempo real (en silla, siguiente, espera estimada). | Must | F2 |
| RF-26 | El cliente ve su turno y tiempo estimado desde la página web (Blade/Alpine). | Should | F2 |
| **Tiempo real** | | | |
| RF-27 | Difusión por Reverb de los eventos de agenda, fila, silla y caja hacia dashboard, app del barbero, página web y TV. | Must | F2 |
| RF-28 | Reconexión automática y resincronización con *snapshot* tras pérdida del WebSocket. | Must | F2 |
| **Finanzas** | | | |
| RF-29 | **Motor de comisiones** con tres estrategias: `percentage`, `fixed_service` y `chair_rental`. | Must | F2 |
| RF-30 | Transacciones inmutables con *snapshot* de la regla aplicada; correcciones mediante reverso. | Must | F2 |
| RF-31 | Caja diaria: ingresos brutos por barbero, desglose por método y separación efectivo vs. digital. | Must | F2 |
| RF-32 | Cierre de caja: conteo de efectivo, congelamiento de transacciones y liquidación por barbero. | Must | F3 |
| RF-33 | Reportes financieros por periodo y exportación CSV. | Should | F3 |
| **Automatización y monetización** | | | |
| RF-34 | Motor de **rescate de huecos muertos**: detecta franjas libres y ofrece cupo a clientes frecuentes cuyo ciclo habitual coincide. | Should | F3 |
| RF-35 | Notificaciones WhatsApp Business: confirmación, recordatorio y ofertas, con plantillas, *opt-in* y registro de entrega. | Should | F3 |
| RF-36 | Suscripciones SaaS: planes, cobro recurrente con pasarela, estados y suspensión. | Must | F3 |
| RF-37 | *Feature gating* y límites por plan (sillas, TV, caja, add-ons). | Must | F3 |
| **Transversales** | | | |
| RF-38 | Auditoría de operaciones críticas con valores antes/después. | Must | F1 |
| RF-39 | Dashboard administrativo con agenda por silla y KPIs del día. | Must | F1 |
| RF-40 | Historial de servicios del cliente en la página web. | Could | F3 |
| RF-41 | Exportación y anonimización de datos personales del cliente a solicitud del titular. | Should | F3 |

---

## 6. Reglas de negocio

### Tenancy y datos

| ID | Regla |
|---|---|
| RN-01 | Todo registro de negocio lleva `tenant_id`. Ninguna consulta se ejecuta sin el *scope* de tenant. |
| RN-02 | `tenants.domain` es único, en minúsculas, `[a-z0-9-]`, de 3 a 63 caracteres. |
| RN-03 | Los teléfonos se normalizan a E.164. `customers` y `users` son únicos por `(tenant_id, phone)`. |
| RN-04 | Fechas en UTC en almacenamiento; la fecha de agenda (`scheduled_date`) es la fecha local del tenant. |
| RN-05 | Los usuarios y servicios con historial no se borran: se desactivan (`is_active = false`). |
| RN-06 | El precio y la duración de cada servicio se copian (*snapshot*) en `appointment_services` al reservar; cambios posteriores no afectan citas existentes. |

### Reserva y agenda

| ID | Regla |
|---|---|
| RN-07 | La cuadrícula de franjas es configurable (5, 10, 15, 20 o 30 min; por defecto 15). |
| RN-08 | Duración ocupada de una cita = Σ `duration_minutes` de sus servicios + el mayor `buffer_minutes` entre ellos (aplicado una vez, al final). |
| RN-09 | Una cita no puede traslapar otra cita activa (`pending`, `confirmed`, `in_chair`) ni un bloqueo de tiempo del mismo barbero. |
| RN-10 | La reserva debe quedar dentro del horario de atención del tenant y del horario del barbero, respetando antelación mínima (por defecto 30 min) y máxima (por defecto 30 días). |
| RN-11 | Hay un solo *hold* activo por sesión de cliente: crear uno nuevo libera el anterior. TTL fijo de **180 s**. |
| RN-12 | El *hold* es una reserva provisional, no una cita: la cita solo existe tras OTP verificado y escritura exitosa bajo *lock*. |
| RN-13 | La confirmación abre una transacción, bloquea la fila del barbero con `SELECT … FOR UPDATE`, revalida solapamientos y recién entonces inserta. Si hay conflicto, devuelve `409` y se pide otra franja. |
| RN-14 | "Primer disponible" elige, entre barberos activos con horario, el que ofrezca la franja más temprana; ante empate, el de menor carga del día. |
| RN-15 | Las operaciones `POST` críticas (confirmar cita, cobrar, registrar *walk-in*) exigen `Idempotency-Key`; repetir la clave devuelve el resultado original. |
| RN-16 | El cliente puede cancelar hasta `cancel_window_minutes` antes de la cita (por defecto 60). Pasado ese límite debe contactar al negocio. |
| RN-17 | Transiciones de estado válidas: `pending → confirmed`, `confirmed → in_chair`, `in_chair → completed`, `pending/confirmed → cancelled`, `confirmed → no_show`. Cualquier otra se rechaza. |
| RN-18 | `pending` identifica citas creadas por el personal que requieren confirmación del cliente (se activa con WhatsApp en F3); en F1 las citas se crean ya `confirmed`. Una cita `pending` expira a los 60 min (configurable). |
| RN-19 | Un barbero no puede tener dos citas `in_chair` a la vez. |
| RN-20 | Una cita `confirmed` no iniciada tras `grace_minutes` (por defecto 15) se sugiere como `no_show`; el barbero o admin lo confirma (no es automático). |
| RN-21 | El Bloqueo Rápido ofrece valores predefinidos (15/30/60 min, configurables). Se rechaza si traslapa una cita `confirmed`/`in_chair`; el sistema informa cuáles. |

### Verificación Zero-Login

| ID | Regla |
|---|---|
| RN-22 | OTP de 6 dígitos, vigencia de 5 min, almacenado como *hash* en Redis, máximo 5 intentos por código. |
| RN-23 | Máximo 3 envíos de OTP por hora por teléfono y 10 por hora por IP. |
| RN-24 | El token de cliente solo permite operar sobre las citas de su propio `customer_id`. Un dispositivo verificado se recuerda 30 días (omite OTP en reservas futuras). |
| RN-25 | El cliente debe aceptar el tratamiento de datos al reservar. El *opt-in* de WhatsApp para mensajes no transaccionales es separado y opcional. |

### Walk-ins y fila

| ID | Regla |
|---|---|
| RN-26 | Un *walk-in* es una cita con `is_walk_in = true` y `queue_position`; su `scheduled_start` es el inicio estimado. |
| RN-27 | El orden de la fila de *walk-ins* es FIFO por hora de llegada. Un *walk-in* solo se inserta en un hueco si **cabe completo** (duración + *buffer*) sin traslapar citas confirmadas, bloqueos ni el servicio en curso. |
| RN-28 | El tiempo estimado de espera se recalcula ante cada cambio (inicio, fin, cancelación, bloqueo, nuevo *walk-in*), considerando el fin esperado del servicio en silla. |
| RN-29 | La Pantalla de TV muestra solo nombre de pila e inicial del apellido; nunca teléfono. El *display token* es de solo lectura y revocable. |

### Finanzas y comisiones

| ID | Regla |
|---|---|
| RN-30 | Solo se cobra una cita en estado `in_chair`. Al cobrar, la cita pasa a `completed`, se crea la transacción y se incrementa `visits_count` en **una sola transacción**. |
| RN-31 | `total_amount` = Σ precios *snapshot* de la cita. Invariante: `total_amount = barber_amount + shop_amount`. |
| RN-32 | Redondeo *half-up* a 2 decimales para `barber_amount`; `shop_amount = total_amount − barber_amount`. |
| RN-33 | `percentage`: `barber_amount = total × rate / 100` (`0 ≤ rate ≤ 100`). |
| RN-34 | `fixed_service`: `barber_amount = min(total, rate × n.º de servicios de la cita)`. |
| RN-35 | `chair_rental`: `barber_amount = total` (el barbero retiene el ingreso) y `shop_amount = 0` por transacción; el alquiler (`rate` = valor diario) se descuenta **una vez por jornada cerrada** con horario programado del barbero. |
| RN-36 | Cada transacción guarda `commission_type` y `commission_rate` vigentes (*snapshot*); cambiar la regla no altera el historial. |
| RN-37 | Las transacciones no se editan ni se eliminan. Un error se corrige con una transacción `reversal` de montos negativos que referencia la original. |
| RN-38 | El cierre de caja congela las transacciones del periodo (`settled_at`) y no puede reabrirse. Un reverso posterior a un cierre se registra en el periodo abierto. |
| RN-39 | Efectivo esperado = Σ pagos `cash` del periodo (menos reversos en efectivo). El cierre registra el efectivo contado y la diferencia. |
| RN-40 | Los métodos de pago habilitados son configurables por tenant (`cash`, `nequi`, `daviplata`, `transfer`, `card`). |

### Automatización, planes y auditoría

| ID | Regla |
|---|---|
| RN-41 | Rescate de huecos: solo a clientes con *opt-in* de WhatsApp, con ciclo promedio de corte coincidente (±3 días) y un hueco ≥ duración de su servicio habitual. Máximo 1 oferta por cliente por semana. |
| RN-42 | La primera aceptación de una oferta gana; la aceptación usa el mismo *hold* + *lock* de la reserva normal. |
| RN-43 | Las notificaciones no transaccionales respetan el *opt-out* y la ventana horaria 7:00–21:00 (hora local del tenant). |
| RN-44 | El plan `free_chair` permite **1 barbero activo**; `pro_barbershop` sillas ilimitadas por tramos; `enterprise` reservado. Exceder el límite bloquea la acción con un mensaje claro. |
| RN-45 | Un tenant `suspended` conserva sus datos, pero no acepta reservas nuevas ni cobros hasta regularizar su suscripción. |
| RN-46 | Se auditan: inicio de sesión, cambios de comisión/precio, cancelaciones, reversos, cierres de caja, cambios de plan y revocación de dispositivos. |

---

## 7. Requisitos no funcionales

| ID | Requisito |
|---|---|
| RNF-01 | Latencia de eventos en tiempo real **p95 < 200 ms** (commit → cliente WebSocket). |
| RNF-02 | `GET` disponibilidad p95 < 300 ms; confirmación de cita p95 < 600 ms. Carga de referencia: 200 tenants, 1.000 conexiones WebSocket concurrentes. |
| RNF-03 | Cero overbooking: 50 solicitudes simultáneas a la misma franja producen exactamente 1 cita. |
| RNF-04 | Cero fugas entre tenants, verificado con suite automatizada. |
| RNF-05 | Disponibilidad objetivo del servicio ≥ 99,5 % mensual en producción. |
| RNF-06 | Página de reserva Blade/Alpine (ADR-005) usable en 3G/4G: primera carga ≤ 250 KB transferidos y TTI ≤ 3 s en 3G rápida (dispositivo de gama media); reserva de cliente recurrente ≤ 15 s. Flutter Web (`client_pwa`) queda experimental y fuera de la ruta crítica. |
| RNF-07 | Modo Silla: iniciar en 1 toque, cobrar en ≤ 2 toques, respuesta visual < 100 ms, objetivos táctiles ≥ 48 dp. |
| RNF-08 | Mobile-first desde 360 px; apps compatibles con Android 8+ (API 26) e iOS 15+. |
| RNF-09 | Accesibilidad básica WCAG 2.1 AA: contraste, etiquetas semánticas y escala de texto hasta 1,3×. |
| RNF-10 | Seguridad: TLS/WSS, OWASP ASVS nivel 2 básico, *rate limiting*, contraseñas con Argon2id/bcrypt, sin datos personales en logs. |
| RNF-11 | Privacidad: cumplimiento de la Ley 1581 de 2012; consentimiento registrado, minimización y derecho de supresión. |
| RNF-12 | Observabilidad: logs JSON con `tenant_id` y `request_id`, métricas (latencia WS, errores, colas) y alertas. |
| RNF-13 | Calidad: PSR-12, Larastan nivel 8, `flutter analyze` limpio; cobertura ≥ 80 % (PHP `Domain`/`Application`) y ≥ 70 % (Flutter `domain`/`data`). |
| RNF-14 | Sin consultas N+1; índices compuestos definidos en el modelo de datos. |
| RNF-15 | Degradación segura: si Redis cae, las reservas siguen protegidas por el *locking* de MySQL (sin *hold*) y el cliente WebSocket recurre a sondeo cada 15 s. |
| RNF-16 | Español (Colombia) por defecto, `COP` y `America/Bogota` configurables por tenant. |
| RNF-17 | Respaldo diario de MySQL con retención de 30 días; RPO ≤ 24 h (objetivo 1 h con *binlog*) y RTO ≤ 4 h. |
| RNF-18 | Escalabilidad horizontal: aplicación *stateless*, sesiones/colas/caché en Redis, Reverb escalado con Redis. |
| RNF-19 | API versionada (`/api/v1`) con mecanismo de versión mínima soportada para las apps móviles. |
| RNF-20 | Migraciones retrocompatibles que permiten despliegue sin tiempo muerto. |

---

## 8. Modelo de datos

Base de datos MySQL 8, esquema compartido con `tenant_id` (UUID, `CHAR(36)`) en todas las tablas de negocio. Todos los `tenant_id` son clave foránea a `tenants.id`.

### 8.1 Entidades núcleo

#### `tenants`

| Campo | Tipo | Notas |
|---|---|---|
| `id` | `CHAR(36)` PK | UUID (ordenado) |
| `domain` | `VARCHAR(100)` | Único; subdominio o identificador |
| `business_name` | `VARCHAR(150)` | |
| `subscription_plan` | `ENUM('free_chair','pro_barbershop','enterprise')` | Por defecto `free_chair` |
| `status` | `ENUM('active','suspended')` | Por defecto `active` |
| `settings` | `JSON` | Horarios de atención, zona horaria, colores, cuadrícula, antelación, ventana de cancelación, gracia, métodos de pago habilitados |
| `created_at`, `updated_at` | `TIMESTAMP` | |

#### `users` (administradores y barberos)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | `BIGINT UNSIGNED` PK | |
| `tenant_id` | `CHAR(36)` FK | |
| `name` | `VARCHAR(100)` | |
| `phone` | `VARCHAR(20)` | E.164 |
| `email` | `VARCHAR(150)` NULL | |
| `password` | `VARCHAR(255)` | *Hash* |
| `role` | `ENUM('admin','barber')` | |
| `commission_type` | `ENUM('percentage','fixed_service','chair_rental')` NULL | Obligatorio para `barber` |
| `commission_rate` | `DECIMAL(8,2)` | Porcentaje, valor fijo por servicio o alquiler diario |
| `is_active` | `BOOLEAN` | |
| `last_login_at` | `DATETIME` NULL | |
| `created_at`, `updated_at` | `TIMESTAMP` | |

Índices: `UNIQUE(tenant_id, phone)`, `INDEX(tenant_id, role, is_active)`.

#### `customers`

| Campo | Tipo | Notas |
|---|---|---|
| `id` | `BIGINT UNSIGNED` PK | |
| `tenant_id` | `CHAR(36)` FK | |
| `name` | `VARCHAR(100)` | |
| `phone` | `VARCHAR(20)` | E.164, indexado |
| `visits_count` | `INT UNSIGNED` | Por defecto 0 |
| `last_visit_at` | `DATETIME` NULL | |
| `preferred_barber_id` | `BIGINT UNSIGNED` NULL FK → `users.id` | |
| `notes` | `TEXT` NULL | Preferencias de corte |
| `whatsapp_opt_in` | `BOOLEAN` | Por defecto `false` |
| `opt_in_at` | `DATETIME` NULL | Evidencia de consentimiento |
| `anonymized_at` | `DATETIME` NULL | Supresión a solicitud |
| `created_at`, `updated_at` | `TIMESTAMP` | |

Índices: `UNIQUE(tenant_id, phone)`, `INDEX(tenant_id, last_visit_at)`.

#### `services`

| Campo | Tipo | Notas |
|---|---|---|
| `id` | `BIGINT UNSIGNED` PK | |
| `tenant_id` | `CHAR(36)` FK | |
| `name` | `VARCHAR(100)` | |
| `price` | `DECIMAL(10,2)` | |
| `duration_minutes` | `INT UNSIGNED` | |
| `buffer_minutes` | `INT UNSIGNED` | Desinfección/preparación |
| `is_active` | `BOOLEAN` | |
| `created_at`, `updated_at` | `TIMESTAMP` | |

Índice: `INDEX(tenant_id, is_active)`.

#### `appointments` (citas y *walk-ins*)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | `BIGINT UNSIGNED` PK | |
| `tenant_id` | `CHAR(36)` FK | |
| `booking_reference` | `CHAR(8)` | Código público; único por tenant |
| `barber_id` | `BIGINT UNSIGNED` FK → `users.id` | |
| `customer_id` | `BIGINT UNSIGNED` FK → `customers.id` | |
| `status` | `ENUM('pending','confirmed','in_chair','completed','cancelled','no_show')` | |
| `scheduled_date` | `DATE` | Fecha local del tenant (denormalizada para índices) |
| `scheduled_start` | `DATETIME` | UTC |
| `scheduled_end` | `DATETIME` | UTC; inicio + Σ duración |
| `buffer_minutes` | `INT UNSIGNED` | *Snapshot* del *buffer* aplicado |
| `actual_start` | `DATETIME` NULL | |
| `actual_end` | `DATETIME` NULL | |
| `is_walk_in` | `BOOLEAN` | Por defecto `false` |
| `queue_position` | `SMALLINT UNSIGNED` NULL | Solo *walk-ins* en espera |
| `total_price` | `DECIMAL(10,2)` | Σ precios *snapshot* |
| `source` | `ENUM('web','barber_app','admin','rescue')` | |
| `cancelled_at` | `DATETIME` NULL | |
| `cancelled_by` | `ENUM('customer','barber','admin','system')` NULL | |
| `cancel_reason` | `VARCHAR(255)` NULL | |
| `created_at`, `updated_at` | `TIMESTAMP` | |

Índices:

- `INDEX(tenant_id, barber_id, scheduled_date, status)` — **obligatorio** (agenda y disponibilidad).
- `INDEX(tenant_id, customer_id, scheduled_start)` — historial del cliente.
- `INDEX(tenant_id, status, scheduled_start)` — recordatorios, expiraciones y rescate.
- `UNIQUE(tenant_id, booking_reference)`.

> **Decisión D-01 (desvío respecto al PRD):** el PRD incluye `service_id` en `appointments`, pero el flujo permite elegir **uno o varios servicios**. Se reemplaza por la tabla pivote `appointment_services`, con *snapshot* de precio y duración.

#### `appointment_services`

| Campo | Tipo | Notas |
|---|---|---|
| `id` | `BIGINT UNSIGNED` PK | |
| `tenant_id` | `CHAR(36)` FK | |
| `appointment_id` | `BIGINT UNSIGNED` FK | |
| `service_id` | `BIGINT UNSIGNED` FK | |
| `service_name` | `VARCHAR(100)` | *Snapshot* |
| `price` | `DECIMAL(10,2)` | *Snapshot* |
| `duration_minutes` | `INT UNSIGNED` | *Snapshot* |
| `buffer_minutes` | `INT UNSIGNED` | *Snapshot* |
| `position` | `TINYINT UNSIGNED` | Orden de ejecución |

#### `transactions` (cobros; inmutables)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | `BIGINT UNSIGNED` PK | |
| `tenant_id` | `CHAR(36)` FK | |
| `appointment_id` | `BIGINT UNSIGNED` FK | |
| `barber_id` | `BIGINT UNSIGNED` FK → `users.id` | |
| `kind` | `ENUM('payment','reversal')` | |
| `reverses_transaction_id` | `BIGINT UNSIGNED` NULL FK | Solo en `reversal` |
| `payment_method` | `ENUM('cash','nequi','daviplata','card','transfer')` | |
| `total_amount` | `DECIMAL(10,2)` | Negativo en reversos |
| `barber_amount` | `DECIMAL(10,2)` | Calculado por el motor de comisiones |
| `shop_amount` | `DECIMAL(10,2)` | `total − barber` |
| `commission_type` | `ENUM('percentage','fixed_service','chair_rental')` | *Snapshot* |
| `commission_rate` | `DECIMAL(8,2)` | *Snapshot* |
| `idempotency_key` | `VARCHAR(64)` | Único por tenant |
| `cash_closing_id` | `BIGINT UNSIGNED` NULL FK | |
| `settled_at` | `DATETIME` NULL | Cierre de caja |
| `created_by` | `BIGINT UNSIGNED` FK → `users.id` | |
| `created_at` | `TIMESTAMP` | Sin `updated_at`: la tabla es de solo inserción |

Índices: `INDEX(tenant_id, barber_id, created_at)`, `INDEX(tenant_id, settled_at)`, `UNIQUE(tenant_id, idempotency_key)`.

### 8.2 Entidades de soporte

| Tabla | Fase | Propósito y campos clave |
|---|---|---|
| `barber_schedules` | F1 | Horario semanal del barbero: `tenant_id`, `barber_id`, `weekday` (0–6), `start_time`, `end_time` (hora local del tenant). |
| `time_blocks` | F1 | Bloqueos: `tenant_id`, `barber_id`, `starts_at`, `ends_at` (UTC), `reason` (`quick_block`, `lunch`, `personal`, `vacation`, `other`), `created_by`. Índice `(tenant_id, barber_id, starts_at)`. |
| `audit_logs` | F1 | `tenant_id`, `user_id`/`customer_id`, `action`, `entity_type`, `entity_id`, `before` (JSON), `after` (JSON), `ip`, `created_at`. |
| `display_devices` | F2 | Pantallas de TV: `tenant_id`, `name`, `token_hash`, `last_seen_at`, `revoked_at`. |
| `cash_closings` | F3 | `tenant_id`, `business_date` (único por tenant), `closed_by`, `gross_total`, `cash_expected`, `cash_counted`, `cash_difference`, `digital_total`, `breakdown` (JSON por método), `closed_at`. |
| `cash_closing_barbers` | F3 | Liquidación por barbero: `cash_closing_id`, `barber_id`, `gross`, `barber_commission`, `shop_share`, `chair_rental_deduction`, `net_payout`. |
| `gap_offers` | F3 | `tenant_id`, `barber_id`, `customer_id`, `slot_start`, `slot_end`, `status` (`sent`, `accepted`, `expired`, `cancelled`), `sent_at`, `expires_at`, `appointment_id`. |
| `notification_logs` | F3 | `tenant_id`, `customer_id`, `channel`, `template`, `status`, `provider_message_id`, `sent_at`. |
| `subscriptions` | F3 | `tenant_id`, `plan`, `status` (`active`, `past_due`, `canceled`), `seats`, `current_period_end`, `provider_reference`. |
| `tenant_addons` | F3 | `tenant_id`, `addon` (`whatsapp_pack`, …), `balance`/`enabled`. |
| `personal_access_tokens` | F1 | Tokens de Sanctum para personal y clientes (`tokenable` polimórfico, `abilities`, `expires_at`). |

### 8.3 Estados de la cita

```
          ┌──────────────┐
          │   pending    │──────────────┐
          └──────┬───────┘              │
                 │ confirmar            │
                 ▼                      ▼
          ┌──────────────┐        ┌───────────┐
          │  confirmed   │───────►│ cancelled │
          └──┬────────┬──┘        └───────────┘
   "Cliente  │        │ no se presentó
   en Silla" │        ▼
             │   ┌─────────┐
             │   │ no_show │
             ▼   └─────────┘
          ┌──────────────┐
          │   in_chair   │
          └──────┬───────┘
                 │ "Finalizar y Cobrar"
                 ▼
          ┌──────────────┐
          │  completed   │
          └──────────────┘
```

### 8.4 Motor de comisiones (RF-29)

Interfaz `CommissionStrategy::calculate(Money $total, int $serviceCount, CommissionRule $rule): CommissionResult`.

| Estrategia | `commission_rate` significa | `barber_amount` | `shop_amount` | Ejemplo (COP) |
|---|---|---|---|---|
| `percentage` | Porcentaje (0–100) | `total × rate / 100` | `total − barber` | Corte $30.000, 40 % → barbero $12.000, local $18.000 |
| `fixed_service` | Monto fijo por servicio | `min(total, rate × n.º servicios)` | `total − barber` | Corte $30.000, fijo $8.000 → barbero $8.000, local $22.000 |
| `chair_rental` | Alquiler **diario** de la silla | `total` | `0` | Jornada $150.000, alquiler $25.000 → en el cierre: barbero neto $125.000, local $25.000 |

El *snapshot* de la regla se guarda en cada transacción (RN-36). El descuento de alquiler se calcula en el cierre de caja (`cash_closing_barbers.chair_rental_deduction`).

### 8.5 Control de concurrencia (RF-09, RF-11)

**Capa 1 — *Cache Hold* (Redis):**

1. El cliente elige franja → `POST /public/holds`.
2. Un *script* Lua atómico verifica que no existan *holds* ni conflictos para ese barbero y rango, y crea `t:{tenantId}:hold:{holdId}` con TTL = 180 s, además de indexarlo en `t:{tenantId}:holds:{barberId}:{date}`.
3. El cálculo de disponibilidad excluye los *holds* vivos. Un nuevo *hold* de la misma sesión libera el anterior (RN-11).

**Capa 2 — *Pessimistic Locking* (MySQL):**

```
BEGIN;
  SELECT id FROM users WHERE id = :barber AND tenant_id = :tenant FOR UPDATE;   -- mutex por silla
  SELECT id FROM appointments
   WHERE tenant_id = :tenant AND barber_id = :barber AND scheduled_date = :date
     AND status IN ('pending','confirmed','in_chair')
     AND scheduled_start < :end AND scheduled_end > :start FOR UPDATE;          -- ¿traslape?
  -- validar bloqueos (time_blocks) y horario
  INSERT appointments + appointment_services;
  -- consumir hold, auditar
COMMIT;   -- luego: emitir eventos (afterCommit)
```

Si hay traslape: `ROLLBACK` y respuesta `409 SLOT_TAKEN`. La capa 2 es la autoridad final; la capa 1 mejora la experiencia y reduce contención.

### 8.6 Algoritmo de inserción de *walk-ins* (RF-23)

1. Calcular `D` = duración ocupada del servicio solicitado (RN-08).
2. Para cada barbero candidato (el elegido, o todos los activos con horario), construir su línea de tiempo: cita `in_chair` (fin esperado = `actual_start` + duración), citas `confirmed`, *walk-ins* ya en cola y bloqueos.
3. Buscar el primer hueco ≥ `D` a partir de `max(ahora, fin del servicio en curso)` que no traslape nada.
4. Entre los candidatos, asignar el de **menor inicio estimado**; ante empate, el de menor carga.
5. Crear la cita `is_walk_in = true` con `queue_position` y `scheduled_start` estimados, bajo el mismo *lock* de la reserva.
6. Emitir `QueueUpdated` y recalcular los tiempos estimados de la fila.

### 8.7 Eventos y canales en tiempo real (RF-27)

| Evento | Se emite cuando | Destinatarios |
|---|---|---|
| `AppointmentConfirmed` | Se confirma una cita | Barbero, dashboard |
| `AppointmentCancelled` | Se cancela una cita | Barbero, dashboard, motor de rescate |
| `AppointmentStatusChanged` | `in_chair`, `completed`, `no_show` | Barbero, dashboard, TV, página web |
| `WalkInQueued` | Se agrega un *walk-in* | Barbero, dashboard, TV, página web |
| `QueueUpdated` | Cambian turnos o tiempos estimados | TV, página web, barbero |
| `ChairBlocked` | Bloqueo rápido o programado | Dashboard, TV, página web (disponibilidad) |
| `TransactionRegistered` | Se registra un cobro | Dashboard (caja), barbero (métricas) |
| `CashClosed` | Se cierra la caja | Dashboard |

Canales (todos con autorización por tenant):

- `private-tenant.{tenantId}.admin`
- `private-tenant.{tenantId}.barber.{barberId}`
- `private-tenant.{tenantId}.queue` (TV con *display token*; cliente con token)
- `private-tenant.{tenantId}.availability.{barberId}` (página web con token de cliente)

Cada *payload* incluye `version`, `emitted_at` (UTC, ms) y `tenant_id`, para medir latencia y ordenar eventos.

---

## 9. Planes SaaS (RF-36, RF-37)

| Capacidad | `free_chair` | `pro_barbershop` | `enterprise` |
|---|:--:|:--:|:--:|
| Barberos / sillas activos | 1 | Ilimitadas (tramos 2–5, 6–10, …) | Reservado |
| Reserva Zero-Login | ✅ | ✅ | ✅ |
| Agenda básica y Modo Silla | ✅ | ✅ | ✅ |
| Gestión de comisiones y cierre de caja | ❌ | ✅ | ✅ |
| Fila Virtual y Pantalla de TV | ❌ | ✅ | ✅ |
| Rescate de huecos | ❌ | ✅ | ✅ |
| Reportes financieros | ❌ | ✅ | ✅ |
| Add-on: paquetes de WhatsApp | Opcional | Opcional | Opcional |
| Add-on: inventario / multi-sucursal | ❌ | Posterior a v1.0 | Posterior a v1.0 |

> La matriz anterior es una **propuesta** derivada del PRD, que no especifica todos los límites. Fue **aprobada en G1
> (2026-11-17)** como línea base de v1.0 (OQ-01); cualquier cambio de precios o límites pasa por control de cambios
> (§14) y se implementa en T-330.

---

## 10. Criterios de aceptación

```gherkin
Escenario: ESC-01 Reserva Zero-Login exitosa
  Dado un cliente que abre el enlace de la barbería "fadespace-demo"
  Cuando elige el servicio "Corte", el barbero "Andrés" y la franja de las 15:00
  Y ingresa su nombre y teléfono y verifica el OTP recibido
  Entonces se crea una cita "confirmed" a su nombre
  Y el barbero y el dashboard reciben el evento AppointmentConfirmed en menos de 200 ms
  Y nunca se le pidió contraseña

Escenario: ESC-02 El hold bloquea la franja para otros clientes
  Dado que el cliente A seleccionó la franja de las 15:00 con Andrés
  Cuando el cliente B consulta la disponibilidad de Andrés
  Entonces la franja de las 15:00 no aparece disponible

Escenario: ESC-03 El hold expira a los 180 segundos
  Dado un hold activo creado hace 181 segundos sin confirmación
  Cuando se consulta la disponibilidad
  Entonces la franja vuelve a estar disponible
  Y confirmar con ese hold devuelve el error "La reserva temporal expiró"

Escenario: ESC-04 Concurrencia sin overbooking
  Dado una franja libre de Andrés a las 16:00
  Cuando 50 solicitudes de confirmación llegan simultáneamente
  Entonces exactamente 1 cita queda creada
  Y las otras 49 reciben 409 "La franja ya no está disponible"

Escenario: ESC-05 OTP inválido o vencido
  Dado un OTP vencido o incorrecto
  Cuando el cliente intenta verificarlo
  Entonces se rechaza sin crear cita
  Y tras 5 intentos fallidos el código se invalida

Escenario: ESC-06 Primer disponible
  Dado dos barberos con horarios libres a las 10:00 y a las 10:30
  Cuando el cliente elige "Primer disponible"
  Entonces se asigna la franja de las 10:00

Escenario: ESC-07 Aislamiento multi-tenant
  Dado dos tenants A y B con datos propios
  Cuando un usuario del tenant A consulta citas, clientes o canales de tiempo real
  Entonces solo obtiene datos del tenant A
  Y cualquier intento de acceder a un recurso del tenant B responde 404

Escenario: ESC-08 Cliente en Silla en un toque
  Dado una cita confirmada en la agenda del barbero
  Cuando el barbero presiona "Cliente en Silla"
  Entonces la cita pasa a "in_chair" y se registra actual_start
  Y la Pantalla de TV muestra al cliente en silla en menos de 200 ms

Escenario: ESC-09 Finalizar y cobrar con comisión porcentual
  Dado un barbero con comisión "percentage" de 40 % y una cita en silla de $30.000
  Cuando presiona "Finalizar y Cobrar" y elige "Nequi"
  Entonces se crea una transacción con total 30000.00, barber_amount 12000.00 y shop_amount 18000.00
  Y la cita queda "completed" y la silla libre
  Y visits_count del cliente aumenta en 1

Escenario: ESC-10 Comisión fija por servicio
  Dado un barbero con comisión "fixed_service" de $8.000 y una cita de $30.000 con 1 servicio
  Cuando se cobra
  Entonces barber_amount es 8000.00 y shop_amount es 22000.00

Escenario: ESC-11 Alquiler de silla en el cierre
  Dado un barbero con "chair_rental" de $25.000 diarios que facturó $150.000 en la jornada
  Cuando el administrador cierra la caja
  Entonces su liquidación muestra bruto 150000.00, alquiler 25000.00 y neto 125000.00

Escenario: ESC-12 Walk-in insertado en un hueco
  Dado un barbero con un hueco libre de 40 minutos antes de su próxima cita confirmada
  Cuando se registra un walk-in de 30 minutos
  Entonces se asigna dentro del hueco y se muestra su tiempo estimado en la TV

Escenario: ESC-13 Walk-in sin hueco suficiente
  Dado un barbero sin huecos que quepan antes de una cita confirmada
  Cuando se registra un walk-in
  Entonces queda en cola después de la cita confirmada sin traslaparla

Escenario: ESC-14 Pantalla de TV en tiempo real
  Dado la Pantalla de TV conectada
  Cuando cambia el estado de la fila o de una silla
  Entonces la pantalla se actualiza con latencia p95 menor a 200 ms
  Y no muestra teléfonos ni apellidos completos

Escenario: ESC-15 Bloqueo rápido de tiempo
  Dado un barbero sin citas en los próximos 30 minutos
  Cuando toca "Bloquear 30 min"
  Entonces la silla deja de ofrecer esas franjas
  Y si hubiera una cita confirmada traslapada, el bloqueo se rechaza y se informa cuál

Escenario: ESC-16 Transacciones inmutables y reverso
  Dado una transacción registrada
  Cuando el administrador necesita corregirla
  Entonces se crea una transacción de reverso con montos negativos que referencia la original
  Y la original no se modifica ni se elimina

Escenario: ESC-17 Cierre de caja
  Dado transacciones del día en efectivo y digitales
  Cuando el administrador cierra la caja con el efectivo contado
  Entonces las transacciones quedan congeladas con settled_at
  Y se registra la diferencia entre efectivo esperado y contado
  Y la caja no puede reabrirse

Escenario: ESC-18 Cancelación por el cliente dentro de la ventana
  Dado una cita confirmada que inicia en más de 60 minutos
  Cuando el cliente la cancela con su token
  Entonces la cita pasa a "cancelled" y la franja queda libre
  Y si faltan menos de 60 minutos se le indica contactar al negocio

Escenario: ESC-19 Rescate de hueco muerto
  Dado una cancelación de última hora y un cliente frecuente con opt-in cuyo ciclo coincide
  Cuando el motor de rescate detecta el hueco
  Entonces le envía una oferta por WhatsApp
  Y la primera aceptación crea la cita y las demás ofertas se cancelan

Escenario: ESC-20 Límite del plan
  Dado un tenant "free_chair" con 1 barbero activo
  Cuando el administrador intenta activar un segundo barbero
  Entonces la acción se bloquea y se ofrece actualizar a "pro_barbershop"

Escenario: ESC-21 Reconexión y resincronización
  Dado un cliente WebSocket que pierde conexión durante 30 segundos
  Cuando se reconecta
  Entonces solicita un snapshot y su vista queda consistente con el servidor

Escenario: ESC-22 Permisos por rol
  Dado un usuario con rol "barber"
  Cuando intenta ver la caja de otros barberos o cambiar comisiones
  Entonces la API responde 403 y la UI no ofrece la acción

Escenario: ESC-23 Límite de envíos de OTP
  Dado un teléfono que ya solicitó 3 OTP en la última hora
  Cuando solicita un cuarto
  Entonces se rechaza con 429 sin enviar mensaje

Escenario: ESC-24 Transición de estado inválida
  Dado una cita "completed"
  Cuando alguien intenta marcarla "in_chair" o "cancelled"
  Entonces la operación se rechaza y el estado no cambia

Escenario: ESC-25 Redis no disponible
  Dado que Redis no responde
  Cuando un cliente confirma una reserva
  Entonces el locking de MySQL impide el overbooking
  Y los clientes en tiempo real recurren a sondeo cada 15 segundos

Escenario: ESC-26 Idempotencia al cobrar
  Dado una solicitud de cobro enviada dos veces con la misma Idempotency-Key
  Cuando el servidor la procesa
  Entonces existe una sola transacción
  Y la segunda respuesta devuelve el resultado de la primera
```

---

## 11. Casos borde

- Dos clientes confirman la misma franja en el mismo milisegundo: gana el primero en obtener el *lock*; el segundo recibe `409`.
- El cliente deja expirar el *hold* mientras espera el OTP: se le ofrece volver a seleccionar, conservando sus datos.
- Cambio de horario de atención con citas ya reservadas fuera del nuevo horario: las citas existentes se conservan y se listan para reubicación.
- Servicio en silla que excede su duración: se recalculan las estimaciones de la fila (RN-28) y se avisa a los clientes afectados.
- Cliente que no llega: el sistema sugiere `no_show` tras el tiempo de gracia; no cambia el estado por sí solo.
- Barbero desactivado con citas futuras: se exige reasignar o cancelar antes de desactivar.
- Cambio de zona horaria del tenant: las citas existentes conservan su instante UTC; solo cambia la presentación.
- Cambio de comisión a mitad de jornada: las transacciones ya registradas conservan su *snapshot*.
- Cierre de caja con transacciones de barberos desactivados: se incluyen en la liquidación.
- Reverso de una transacción ya cerrada: se registra en el periodo abierto, referenciando la original.
- Cobro enviado sin conexión: la app reintenta con la misma `Idempotency-Key`; nunca duplica.
- Teléfono ya existente con distinto nombre: se conserva el cliente y se actualiza el nombre más reciente sin perder historial.
- Cliente que solicita supresión de datos: se anonimiza (`anonymized_at`) conservando la integridad financiera.
- Tenant `suspended`: el enlace público muestra un aviso y bloquea reservas; los datos se conservan.
- Pantalla de TV con token revocado: deja de recibir datos y muestra pantalla de reconexión.
- OTP enviado a un número sin WhatsApp: *fallback* a SMS configurable.

---

## 12. Preguntas abiertas — resueltas en G1/G2 (2026-11-17)

| ID | Pregunta | Impacto | Propuesta provisional | Resolución |
|---|---|---|---|---|
| OQ-01 | ¿Cuál es la matriz exacta de funcionalidades y precios por plan? | RF-36, RF-37 | Usar la matriz de §9 y validar con negocio | **Aceptada.** Matriz de §9 como línea base de v1.0; ajustes de precio o límites vía control de cambios y T-330. |
| OQ-02 | El PRD menciona "sucursales" y un add-on multi-sucursal, pero el modelo núcleo no tiene tabla de sedes. ¿Se asume una sede por tenant en v1.0? | Modelo de datos, reportes | **Sí**: una sede por tenant; sedes en versión posterior | **Aceptada.** Una sede por tenant en v1.0; multi-sucursal permanece en el backlog (§13). |
| OQ-03 | ¿Qué proveedor de SMS/WhatsApp entrega el OTP en F1, si WhatsApp Business API llega recién en F3? | RF-10, RF-35 | Interfaz `OtpChannel` con proveedor SMS en F1 (ADR-006) y WhatsApp en F3 | **Aceptada.** SMS transaccional en F1 detrás de `OtpChannel` (ADR-006) y WhatsApp Cloud API en F3. |
| OQ-04 | ¿Qué pasarela de pagos se usará para suscripciones? | RF-36 | Decidir en ADR antes de F3 (Wompi/Stripe/otra) | **Aceptada.** Se decide en ADR-008 antes de F3 (T-331); no bloquea F1. |
| OQ-05 | ¿Se permitirán propinas, descuentos o servicios adicionales al cobrar? | RN-31 | Excluido en v1.0 (backlog) | **Aceptada.** Sin propinas, descuentos ni adicionales en v1.0; quedan en el backlog. |
| OQ-06 | ¿El tamaño de Flutter Web cumple el presupuesto de 3G? | RNF-06 | *Spike* en F0 (T-009); alternativa: página de reserva liviana en Blade/Alpine | **Resuelta.** Flutter Web no cumple (2,32 MB, sin LCP/TTI medibles); el embudo público pasa a página Blade/Alpine (ADR-005) y `client_pwa` queda experimental (T-160…T-165 re-planificadas). |
| OQ-07 | ¿Qué efectivo "en caja" excluye pagos de liquidación a barberos? | RN-39 | v1.0 solo registra efectivo esperado vs. contado; retiros de caja en backlog | **Aceptada.** Solo efectivo esperado vs. contado; retiros de caja en el backlog. |

> **Acta de puertas:** G1 y G2 aprobadas por Diego Alejandro Zamora Gallego el 2026-11-17. Las propuestas de
> OQ-01…OQ-05 y OQ-07 se aceptan tal cual; OQ-06 se resuelve con ADR-005. El cambio de alcance asociado se registra
> en §14.

---

## 13. Backlog posterior (v1.1+)

- Multi-sucursal.
- Inventario y comisiones por venta de productos.
- Propinas, descuentos y servicios adicionales al cobrar.
- Notificaciones *push* nativas para el barbero.
- Pagos o depósitos en línea de la cita por el cliente.
- Servicios habilitados por barbero y duración personalizada por barbero.
- Panel de plataforma (*super-admin*) de Bloxysoft.
- Lista de espera inteligente y reprogramación automática.
- Reportes avanzados y tablero de retención de clientes.

---

## 14. Registro de cambios

| ID | Fecha | Cambio | Justificación | Puerta |
|---|---|---|---|---|
| CC-01 | 2026-11-17 | Aprobación de la especificación; OQ-01…OQ-07 resueltas en §12; matriz de planes de §9 aceptada como línea base. | Cierre de G1 y de las preguntas abiertas que bloqueaban F1. | G1 |
| CC-02 | 2026-11-17 | Enmienda de alcance por ADR-005: el embudo público de reserva se sirve con Blade/Alpine y RNF-06 pasa a ≤ 250 KB/TTI ≤ 3 s; `client_pwa` queda experimental. Se re-planifican T-160…T-165 y se crea T-100 para validar Docker y CI remoto. | El *spike* T-009 midió 2,32 MB (> 2 MB) y TTI no medible; la validación de infraestructura no era posible en F0. | G2 |
